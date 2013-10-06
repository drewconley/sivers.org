require 'sinatra/base'
require 'sinatra/cookies'
require 'json'
require_relative 'models.rb'

## DYNAMIC PATHS for nginx to pass to proxy:
# /comments
# /thanks/
# /sorry/
# /list/
# /u/
# /ayw/
# /download/

class SiversOrg < Sinatra::Base
  helpers Sinatra::Cookies

  # nginx might rewrite looking for /uri/home or just /uri/. both are wrong.
  get %r{/home\Z|/\Z} do
    redirect '/'
  end

  # COMMENTS: JavaScript get JSON
  get %r{\A/comments/([a-z0-9_-]+).json\Z} do |uri|
    content_type 'application/json'
    Comment.for_uri(uri).to_json
  end

  # COMMENTS: post to add comment
  post '/comments' do
    comment_id = Comment.add(request.env)
    if comment_id
      Comment.log('good', request.env)
      redirect '%s#comment-%d' % [request.referrer, comment_id]
    else
      Comment.log('bad', request.env)
      redirect request.referrer
    end
  end

  # THANKS - for what?
  get %r{\A/thanks/([a-z]+)\Z} do |forwhat|
    @bodyid = 'thanks'
    @pagetitle = 'Thank you!'
    thanks = Hash.new('')  # default message?
    thanks['list'] = 'I updated your email list settings.</p><p>Your info is private and will never be sold to anyone else, ever.</p><p>Of course you can email me anytime at <a href="mailto:derek@sivers.org">derek@sivers.org</a>'
    thanks['reset'] = 'Wait a minute, then check your inbox for an email from derek@sivers.org with the subject “your password reset link”.</p><p>If you don’t get it in a minute or two, please email me to let me know.'
    thanks['ayw'] = 'Wait a minute, then check your inbox for an email from derek@sivers.org with the subject “your MP3 download link”.</p><p>If you don’t get it in a minute or two, please email me to let me know.'
    thanks['pdf'] = 'Wait a minute, then check your inbox for an email from derek@sivers.org with the subject “How to Call Attention to Your Music”.</p><p>If you don’t get it in a minute or two, please email me to let me know.'
    @message = thanks[forwhat]
    erb :oneliner
  end

  # SORRY - for what?
  get %r{\A/sorry/([a-z]+)\Z} do |forwhat|
    @bodyid = 'sorry'
    @pagetitle = 'Sorry!'
    sorry = Hash.new('')  # default message?
    sorry['badurlid'] = 'That unique URL is not right, for some reason.</p><p>Maybe it expired? Maybe it has changed since I emailed it to you?</p><p><a href="/ayw/login">Click here to try to log in</a>.</p><p>If that doesn’t work, email me at <a href="mailto:derek@sivers.org">derek@sivers.org</a>'
    sorry['shortpass'] = 'Your password needs to be at least 4 characters long.</p><p>Please go back to try again.'
    sorry['noemail'] = 'That email address wasn’t found. Do you have another?</p><p>Please go back to try again.'
    sorry['aywcode'] = 'That wasn’t the code word.</p><p>HINT: It starts with a U and ends with an A.</p><p>Please go back to try again.'
    sorry['login'] = 'You need to login to be here'
    sorry['badlogin'] = 'Either the email address or password wasn’t right.</p><p>Please go back to try again.'
    @message = sorry[forwhat]
    erb :oneliner
  end

  # LIST: pre-authorized URL to show form for changing settings / unsubscribing
  get %r{\A/list/([0-9]+)/([a-zA-Z0-9]{4})\Z} do |person_id, lopass|
    @bodyid = 'list'
    @pagetitle = 'email list'
    p = Person.where(id: person_id, lopass: lopass).first
    @show_name = p ? p.name : ''
    @show_email = p ? p.email : ''
    erb :list
  end

  # LIST: just show the static form
  get '/list' do
    @bodyid = 'list'
    @pagetitle = 'email list'
    @show_name = @show_email = ''
    erb :list
  end

  # LIST: handle posting of list signup or changing settings
  post '/list' do
    EmailList.update(request.env)
    redirect '/thanks/list'
  end

  # DOWNLOAD: lopass auth to get a file from S3
  get %r{\A/download/([0-9]+)/([a-zA-Z0-9]{4})/([a-zA-Z0-9\._-]+)\Z} do |person_id, lopass, filename|
    p = Person.where(id: person_id, lopass: lopass).first
    redirect '/sorry/login' unless p
    nu = {person_id: p.id, statkey: 'download', statvalue: filename}
    Userstat.create(nu)
    redirect AYW.url_for(filename)
  end

  # sivers.org/pdf posts here to get ebook
  # TODO: merge this AYW stuff into others
  post '/download/ebook' do
    redirect '/pdf' unless AYW.valid?(request.env)
    nu = {person_id: AYW.person_id(request.env), statkey: 'ebook', statvalue: 'requested'}
    Userstat.create(nu)
    p = Person[nu[:person_id]]
    f = Formletter[Sivers.config['formletter_download_pdf']]
    h = {profile: 'derek@sivers', subject: p.firstname + ' - How to Call Attention To Your Music'}
    f.send_to(p, h)
    redirect '/thanks/pdf'
  end

  # PASSWORD: semi-authorized. show form to make/change real password
  get %r{\A/u/([0-9]+)/([a-zA-Z0-9]{8})\Z} do |person_id, newpass|
    p = Person.where(id: person_id, newpass: newpass).first
    redirect '/sorry/badurlid' unless p
    @person_id = person_id
    @newpass = newpass
    @bodyid = 'newpass'
    @pagetitle = 'new password'
    erb :newpass
  end

  # PASSWORD: posted here to make/change it. then log in with cookie
  post '/u/password' do
    p = Person.where(id: params[:person_id], newpass: params[:newpass]).first
    redirect '/sorry/badurlid' unless p
    redirect '/sorry/shortpass' unless params[:password].to_s.size >= 4
    p.set_password(params[:password])
    p.set_newpass
    if ['sivers.org', 'sivers.dev', 'example.org'].include? request.env['SERVER_NAME']
      cookies['ok'] = Login.set_auth(p.id, request.env['SERVER_NAME'])
    end
    redirect '/ayw/list'   # TODO: other destinations in future
  end

  # PASSWORD: forgot? form to enter email
  get '/u/forgot' do
    @bodyid = 'forgot'
    @pagetitle = 'forgot password'
    erb :forgot
  end

  # PASSWORD: email posted here. send password reset link
  post '/u/forgot' do
    p = Person[email: params[:email]]
    redirect '/sorry/noemail' unless p
    p.set_newpass
    f = Formletter[Sivers.config['formletter_password_reset']]
    h = {profile: 'derek@sivers', subject: p.firstname + ' - your password reset link'}
    f.send_to(p, h)
    redirect '/thanks/reset'
  end

  # AYW post code word + name & email. if right, emails login link
  # (if you are reading this, yes the codeword is here. it's intentionally not very secret.)
  post '/ayw/proof' do
    redirect '/sorry/aywcode' unless /utopia/i === params[:code]
    p = AYW.update(request.env)
    f = Formletter[Sivers.config['formletter_ayw_bought']]
    h = {profile: 'derek@sivers', subject: p.firstname + ' - your MP3 download link'}
    f.send_to(p, h)
    redirect '/thanks/ayw'
  end

  # log in form to get to AYW MP3 download area
  get '/ayw/login' do
    p = Login.get_person_from_cookie(cookies['ok'])
    redirect '/ayw/list' if p
    @bodyid = 'ayw'
    @pagetitle = 'log in for MP3 downloads'
    erb :ayw_login
  end

  # post login form to get into list of MP3s
  post '/ayw/login' do
    p = Person.find_by_email_pass(params[:email], params[:password])
    if p && (['sivers.org', 'sivers.dev', 'example.org'].include? request.env['SERVER_NAME'])
      cookies['ok'] = Login.set_auth(p.id, request.env['SERVER_NAME'])
      redirect '/ayw/list'
    else
      redirect '/sorry/badlogin'
    end
  end

  # AYW list of MP3 downloads - only for the authorized
  get '/ayw/list' do
    p = Login.get_person_from_cookie(cookies['ok'])
    redirect '/ayw/login' unless p
    @bodyid = 'ayw'
    @pagetitle = 'MP3 downloads for Anything You Want book'
    erb :ayw_list
  end

  # AYW MP3 downloads - if authorized, redirect to S3
  get %r{\A/ayw/download/([A-Za-z-]+.zip)\Z} do |zipfile|
    p = Login.get_person_from_cookie(cookies['ok'])
    redirect '/sorry/login' unless p
    redirect AYW.url_for(zipfile)
  end

end
