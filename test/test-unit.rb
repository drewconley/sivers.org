require 'test/unit'
require_relative '../models.rb'

class TestComments < Test::Unit::TestCase

  def setup
    @good = {
      'HTTP_REFERER' => 'http://sivers.org/trust',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64; rv:22.0) Gecko/20100101 Firefox/22.0',
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

  def test_spam
    refute Comment.spam?(@good)
    bad = @good.dup
    bad['rack.request.form_hash']['name'] = 'viagra-test-123'
    assert Comment.spam?(bad)
  end

  def test_clean
    h = @good['rack.request.form_hash']
    nu = {uri: 'trust', name: h['name'], email: h['email'], ip: @good['REMOTE_ADDR'], html: h['comment']}
    assert_equal nu, Comment.clean(@good)
    bad = @good.clone
    bad['rack.request.form_hash']['name'] = '  Some Name '
    bad['rack.request.form_hash']['email'] = '  derek@sivers.org '
    bad['rack.request.form_hash']['url'] = 'sivers.org/'
    bad['rack.request.form_hash']['comment'] = 'Sure is a nice day for <a href="http://yeah.xxx">this</a>'
    assert_equal nu, Comment.clean(bad)
  end

  def test_person_id
    nu = Comment.clean(@good)
    assert Comment.person_id(nu) < 10
    nu[:email] = 'abc@defg.hi'
    assert Comment.person_id(nu) > 300000
    Person[email: nu[:email]].destroy
  end

  def test_add
    comment_id = Comment.add(@good)
    assert comment_id.instance_of? Fixnum
    assert comment_id > 40000
  end

  def test_ayw_download
    file = 'JAZZ-AnythingYouWant.zip'
    u = AYW.url_for(file)
    assert u.start_with? "https://s3-us-west-1.amazonaws.com/aywb/#{file}?AWSAccessKeyId="
  end

end

