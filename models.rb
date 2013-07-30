require 'json'
require 'sequel'
require 'peeps'
require 'aws/s3'
require 'resolv'
require 'rakismet'

class Sivers
  DB = Sequel.postgres('sivers', user: 'sivers')

  # config keys: 'project_honeypot_key', 's3key', 's3secret', 'akismet'
  def self.config
    unless @config
      @config = JSON.parse(File.read(File.dirname(__FILE__) + '/config.json'))
      @config['url_regex'] = %r{\Ahttps?://sivers\.(dev|org)/([a-z0-9_-]{1,32})\Z}
      @config['formletter_password_reset'] = 1
      @config['formletter_ayw_bought'] = 4
      @config['formletter_download_pdf'] = 5
    end
    @config
  end
end

# https://github.com/joshfrench/rakismet
Rakismet.key = Sivers.config['akismet']
Rakismet.url = 'http://sivers.org/'
Rakismet.host= 'rest.akismet.com'
class Akismet
  include Rakismet::Model
  def initialize(uri, env)
    @author = env['rack.request.form_hash']['name']
    @author_url = env['rack.request.form_hash']['url']
    @author_email = env['rack.request.form_hash']['email']
    @content = env['rack.request.form_hash']['comment']
    @permalink = "http://sivers.org/#{uri}"
    @user_ip = env['REMOTE_ADDR']
    @user_agent = env['HTTP_USER_AGENT']
    @referrer = env['HTTP_REFERER']
  end
end

# comments stored in database
class Comment < Sequel::Model(Sivers::DB)
  class << self

    # return array of hashes of comments for this URI
    # used by JavaScript GET /comments/trust.json
    def for_uri(uri)
      select(:id, :created_at, :html, :name, :url).where(uri: uri).order(:id).map(&:values)
    end

    def valid_url?(request_env)
      Sivers.config['url_regex'] === request_env['HTTP_REFERER']
    end

    def valid_ip?(request_env)
      /\A[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\Z/ === request_env['REMOTE_ADDR']
    end

    def valid_fields?(request_env)
      return false unless request_env['rack.request.form_hash'].instance_of?(Hash)
      %w(name email comment).each do |fieldname|
        return false unless request_env['rack.request.form_hash'][fieldname].size > 0
      end
      /\A\S+@\S+\.\S+\Z/ === request_env['rack.request.form_hash']['email'].strip
    end

    # comment posted from form. valid data submitted?
    def valid?(request_env)
      return false unless valid_url?(request_env)
      return false unless valid_ip?(request_env)
      return false unless valid_fields?(request_env)
      true
    end

    # Project Honeypot DNS lookup of commenter's IP
    def spammer?(ip)
      query = Sivers.config['project_honeypot_key'] + '.' + ip.split('.').reverse.join('.') + '.dnsbl.httpbl.org'
      begin
        Timeout::timeout(1) do
        response = Resolv::DNS.new.getaddress(query).to_s
        if /127\.[0-9]+\.([0-9]+)\.[0-9]+/.match response
          return true if $1.to_i > 5
        end
        false
      end
      rescue
        false
      end
    end

    # return params, cleaned up values & keys, ready to insert
    def clean(request_env)
      h = request_env['rack.request.form_hash'].clone
      Sivers.config['url_regex'].match request_env['HTTP_REFERER']
      nu = {uri: $2}
      nu[:name] = h['name'].strip
      nu[:email] = h['email'].strip.downcase
      nu[:ip] = request_env['REMOTE_ADDR']
      h['url'].strip!
      if h['url'].size > 5
        unless %r{\Ahttps?://} === h['url']
          h['url'] = 'http://' + h['url']
        end
        nu[:url] = h['url']
      end
      nu[:html] = h['comment'].force_encoding('utf8').gsub(%r{</?[^>]+?>}, '')
      nu
    end

    # find or add person in peeps.people. return person_id either way.
    def person_id(params)
      p = Person[email: params[:email]]
      if p.nil?
        p = Person.create(name: params[:name], email: params[:email])
      end
      p.id
    end

    # USE THIS from controller. Pass request.env as-is.
    # Returns comment.id if successful, FALSE if not.
    def add(request_env)
      return false unless valid?(request_env)
      return false if spammer?(request_env['REMOTE_ADDR'])
      nu = clean(request_env)
      a = Akismet.new(nu[:uri], request_env)
      return false if a.spam?
      nu[:person_id] = person_id(nu)
      c = create(nu)
      c.id
    end

  end
end

# wrapper around peeps.userstats
class EmailList
  class << self
    def valid?(request_env)
      return false unless request_env['rack.request.form_hash']['name'].size > 0
      /\A\S+@\S+\.\S+\Z/ === request_env['rack.request.form_hash']['email'].strip
    end

    # return params, cleaned up values & keys, ready to insert
    def clean(request_env)
      h = request_env['rack.request.form_hash'].clone
      nu = {statkey: 'listype', ip: request_env['REMOTE_ADDR']}
      nu[:statvalue] = (%w(some all none).include? h['listype']) ? h['listype'] : 'some'
      nu
    end

    def person_id(request_env)
      name = request_env['rack.request.form_hash']['name'].strip
      email = request_env['rack.request.form_hash']['email'].strip.downcase
      p = Person[email: email]
      if p.nil?
        p = Person.create(name: name, email: email)
      end
      p.id
    end

    def update(request_env)
      return false unless valid?(request_env)
      return false if Comment.spammer?(request_env['REMOTE_ADDR'])
      nu = clean(request_env)
      nu[:person_id] = person_id(request_env)
      Userstat.create(nu)
      Person[nu[:person_id]].update(listype: nu[:statvalue])
    end
  end
end

# need to merge these some day soon
# this one is logging proof they bought AYW book, and sending reset email
class AYW
  class << self
    def valid?(request_env)
      return false unless request_env['rack.request.form_hash']['name'].size > 0
      /\A\S+@\S+\.\S+\Z/ === request_env['rack.request.form_hash']['email'].strip
    end

    def person_id(request_env)
      name = request_env['rack.request.form_hash']['name'].strip
      email = request_env['rack.request.form_hash']['email'].strip.downcase
      p = Person[email: email]
      if p.nil?
        p = Person.create(name: name, email: email)
      else
	p.set_lopass
	p.set_newpass
      end
      p.id
    end

    def update(request_env)
      return false unless valid?(request_env)
      nu = {person_id: person_id(request_env), statkey: 'ayw', statvalue: 'a'}
      Userstat.create(nu)
      Person[nu[:person_id]]
    end

    def url_for(filename)
      AWS::S3::DEFAULT_HOST.replace 's3-us-west-1.amazonaws.com'
      AWS::S3::Base.establish_connection!(
        access_key_id: Sivers.config['s3key'],
        secret_access_key: Sivers.config['s3secret'])
      AWS::S3::S3Object.url_for(filename, 'aywb', :use_ssl => true)
    end
  end
end

