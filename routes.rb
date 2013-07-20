require 'sinatra'
require 'json'
require_relative 'models.rb'

get %r{/comments/([a-z0-9_-]+).json} do |uri|
  content_type 'application/json'
  Comment.for_uri(uri).to_json
end

post '/comments' do
end
