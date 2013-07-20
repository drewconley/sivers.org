require 'json'
require 'sequel'
DB = Sequel.postgres('sivers', user: 'sivers')

class Sivers
  # config keys: 'project_honeypot_key'
  def self.config
    unless @config
      @config = JSON.parse(File.read('./config.json'))
    end
    @config
  end
end

# comments stored in database
class Comment < Sequel::Model(:comments)
  class << self

    # return array of hashes of comments for this URI
    # used by JavaScript GET /comments/trust.json
    def for_uri(uri)
      select(:id, :created_at, :html, :name, :url).where(uri: uri).order(:id).map(&:values)
    end

    # comment posted from form. valid data submitted?
    def valid?(params)
    end

    # Project Honeypot DNS lookup of commenter's IP
    def spammer?(ip)
    end

    # return params, cleaned up values & keys, ready to insert
    def clean(params)
    end

    # find or add person in peeps.people. return person_id either way.
    def person_id(params)
    end

    # USE THIS from controller. Pass posted params as-is.
    # Returns comment.id if successful, FALSE if not.
    def add(params)
      return false unless valid?(params)
      return false if spammer?(request.remote_ip)
      nu = clean(params)
      nu[:person_id] = person_id(nu)
      c = create(nu)
    end

  end
end
