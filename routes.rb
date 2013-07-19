require 'sinatra'
require 'sequel'
require 'json'
DB = Sequel.postgres('sivers', user: 'sivers')

get %r{/comments/([a-z0-9_-]+).json} do |uri|
  content_type 'application/json'
  DB[:comments].select(:id, :created_at, :html, :name, :url).where(uri: uri).order(:id).all.to_json
end
