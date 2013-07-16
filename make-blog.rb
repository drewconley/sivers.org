require 'erb'
require 'date'

def template(name)
  ERB.new(File.read("templates/#{name}.erb"))
end

@blogs = []
Dir['blog/20*'].each do |infile|
  /(\d{4}-\d{2}-\d{2})-(\S+)/.match File.basename(infile)
  @date = $1
  @year = @date[0,4]
  @url = $2
  lines = File.readlines(infile)
  /<!--\s+(.+)\s+-->/.match lines.shift
  @title = $1
  body = lines.join('')

  @pagetitle = "#{@title} | Derek Sivers"
  @bodyid = 'oneblog'

  # PAGE STRUCTURE
  html = template('header').result
  html << template('bloghead').result
  html << body
  html << template('blogfoot').result
  html << template('comments').result
  html << template('footer').result

  File.open("site/#{@url}", 'w') {|f| f.puts html }

  @blogs << {date: @date, url: @url, title: @title}
end
@blogs.sort_by!{|x| x[:date]}
@blogs.reverse!

# BLOG PAGE
@pagetitle = 'Derek Sivers Blog'
@bodyid = 'bloglist'
html = template('header').result
html << template('bloglist').result
html << template('footer').result
File.open('site/blog', 'w') {|f| f.puts html }

@tweets = []
Dir['tweets/20*'].each do |infile|
  /^(\d{4}-\d{2}-\d{2})/.match File.basename(infile)
  date = $1
  d = Date.parse(date)
  tweet = File.read(infile).strip
  @tweets << {date: date, show_date: d.strftime('%B %-d'), show_year: d.strftime('%B %-d, %Y'), tweet: tweet}
end
@tweets.sort_by!{|x| x[:date]}
@tweets.reverse!

# TWEETS PAGE
@pagetitle = 'Derek Sivers Tweets'
@bodyid = 'tweets'
html = template('header').result
html << template('tweets').result
html << template('footer').result
File.open('site/tweets', 'w') {|f| f.puts html }

# HOME PAGE
@new_blogs = @blogs[0,6]
@new_tweets = @tweets[0,6]
@pagetitle = 'Derek Sivers'
@bodyid = 'home'
html = template('header').result
html << template('home').result
html << template('footer').result
File.open('site/home', 'w') {|f| f.puts html }

