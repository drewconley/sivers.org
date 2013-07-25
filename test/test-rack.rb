ENV['testing'] = 'test'
require 'test/unit'
require 'rack/test'
require_relative '../routes.rb'

class SiversOrgTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Fixtures::Tools

  def app
    SiversOrg.new
  end

  def test_thanks
    get '/thanks/list'
    assert last_response.body.include? 'I updated your email list settings'
    get '/thanks/whatever'
    assert last_response.body.include? 'Thank you!'
  end

  def test_sorry
    get '/sorry/badurlid'
    assert last_response.body.include? 'URL is not right'
    get '/sorry/whatever'
    assert last_response.body.include? 'Sorry!'
  end

  def test_list_lopass
    p = Person[7]
    get '/list/%d/%s' % [7, p.lopass]
    assert last_response.body.include? p.name
    assert last_response.body.include? p.email
    get '/list/%d/%s' % [7, 'abcd']
    assert last_response.body.include? 'email list'
    refute last_response.body.include? p.name
    get '/list/1/abcde'
    assert_equal 404, last_response.status
  end

  def test_u_newpass
    p = Person[6]
    get '/u/%d/%s' % [p.id, p.newpass]
    assert last_response.body.include? p.newpass
    get '/u/1/abcdefgh'
    assert_equal 302, last_response.status
  end

  def test_u_password
    p = Person[5]
    newpass = p.newpass
    nupass = 'new?new!new'
    post '/u/password', {person_id: 5, newpass: newpass, password: nupass}
    p2 = Person.find_by_email_pass(p.email, nupass)
    assert_equal p.email, p2.email
    refute_equal newpass, p2.newpass
  end

end
