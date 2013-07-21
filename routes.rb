require 'sinatra'
require 'json'
require_relative 'models.rb'

# COMMENTS: JavaScript get JSON
get %r{\A/comments/([a-z0-9_-]+).json\Z} do |uri|
  content_type 'application/json'
  Comment.for_uri(uri).to_json
end

# COMMENTS: post to add comment
post '/comments' do
  comment_id = Comment.add(request.env)
  if comment_id
    redirect '%s#comment-%d' % [request.referrer, comment_id]
  else
    redirect request.referrer
  end
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
  # TODO: send to thanks
end

# PASSWORD: semi-authorized. show form to make/change real password
get %r{\A/u/([0-9]+)/([a-zA-Z0-9]{8})\Z} do |person_id, newpass|
end

# PASSWORD: posted here to make/change it. then log in with cookie
post '/u/password' do
end

# PASSWORD: forgot? form to enter email
get '/u/forgot' do
end

# PASSWORD: email posted here. send password reset link
post '/u/forgot' do
end

# AYW post code word + name & email. if right, emails login link
post '/ayw/proof' do
end

# AYW list of MP3 downloads - only for the authorized
get '/ayw/list' do
end

# AYW MP3 downloads - if authorized, redirect to S3
get %r{\A/ayw/download/([A-Za-z-]+.zip)\Z} do |zipfile|
end

