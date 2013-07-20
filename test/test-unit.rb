require 'test/unit'
require_relative '../models.rb'

class TestComments < Test::Unit::TestCase

  def setup
    @good = {
      'HTTP_REFERER' => 'http://sivers.org/trust',
      'REMOTE_ADDR' => '5.9.59.61',
      'rack.request.form_hash' => {
	'name' => 'Some Name',
	'email' => 'derek@sivers.org',
	'url' => 'http://sivers.org/',
	'comment' => 'Sure is a nice day for this'}}
  end

  def test_valid_url
    assert Comment.valid_url?(@good)
    bad_refer = @good.clone
    bad_refer['HTTP_REFERER'] = 'http://evil.net/'
    refute Comment.valid_url?(bad_refer)
    bad_refer['HTTP_REFERER'] = 'http://sivers.org/trust?extra=stuff'
    refute Comment.valid_url?(bad_refer)
  end

  def test_valid_ip
    assert Comment.valid_ip?(@good)
    bad_ip = @good.clone
    bad_ip['REMOTE_ADDR'] = ''
    refute Comment.valid_ip?(bad_ip)
  end

  def test_valid_fields
    assert Comment.valid_fields?(@good)
    bad_fields = @good.clone
    bad_fields['rack.request.form_hash']['email'] = 'mac@aol'
    refute Comment.valid_fields?(bad_fields)
  end

  def test_valid
    assert Comment.valid?(@good)
    bad_fields = @good.clone
    bad_fields['rack.request.form_hash']['email'] = 'mac@aol'
    refute Comment.valid?(bad_fields)
  end

  def test_spammer
    refute Comment.spammer?(@good['REMOTE_ADDR'])
    assert Comment.spammer?('127.1.80.1')
  end

  def test_clean
    h = @good['rack.request.form_hash']
    nu = {name: h['name'], email: h['email'], ip: @good['REMOTE_ADDR'], url: h['url'], html: h['comment']}
    assert_equal nu, Comment.clean(@good)
    bad = @good.clone
    bad['rack.request.form_hash']['name'] = '  Some Name '
    bad['rack.request.form_hash']['email'] = '  derek@sivers.org '
    bad['rack.request.form_hash']['url'] = 'sivers.org/'
    bad['rack.request.form_hash']['comment'] = 'Sure is a nice day for <a href="http://yeah.xxx">this</a>'
    assert_equal nu, Comment.clean(bad)
  end
end
