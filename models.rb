require 'sequel'
DB = Sequel.postgres('sivers', user: 'sivers')

class Comment < Sequel::Model(:comments)
  
  def self.for_uri(uri)
    select(:id, :created_at, :html, :name, :url).where(uri: uri).order(:id).map(&:values)
  end

end
