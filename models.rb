require 'json'
require 'sequel'
DB = Sequel.postgres('sivers', user: 'sivers')

class Sivers
  def self.config
    unless @config
      @config = JSON.parse(File.read('./config.json'))
    end
    @config
  end
end

class Comment < Sequel::Model(:comments)
  class << self
    def for_uri(uri)
      select(:id, :created_at, :html, :name, :url).where(uri: uri).order(:id).map(&:values)
    end
  end
end
