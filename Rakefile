require 'erb'
require 'date'
require 'atom'
# gem install libxml-ruby
# git clone git://github.com/seangeo/ratom.git
# remove dependencies
# gem build ratom.gemspec
# gem install ratom-*.gem

def template(name)
  ERB.new(File.read("templates/#{name}.erb"))
end

class String
  def autolink
    self.gsub(/(http\S*)/, '<a href="\1">\1</a>')
  end
end

desc "build site/ from content/ and templates/"
task :make do
  ########## READ, PARSE, AND WRITE BLOG POSTS
  @blogs = []
  Dir['content/blog/20*'].sort.each do |infile|

    # PARSE. Filename: yyyy-mm-dd-uri
    /(\d{4}-\d{2}-\d{2})-(\S+)/.match File.basename(infile)
    @date = $1
    @url = $2
    @year = @date[0,4]
    lines = File.readlines(infile)
    /<!--\s+(.+)\s+-->/.match lines.shift
    @title = $1
    @body = lines.join('')
    @pagetitle = "#{@title} | Derek Sivers"
    @bodyid = 'oneblog'

    # merge with templates and WRITE file
    html = template('header').result
    html << template('blog').result
    html << template('comments').result
    html << template('footer').result
    File.open("site/#{@url}", 'w') {|f| f.puts html }

    # save to array for later use in index and home page
    @blogs << {date: @date, url: @url, title: @title, html: @body}
  end


  ########## WRITE BLOG INDEX PAGE
  @blogs.reverse!
  @pagetitle = 'Derek Sivers Blog'
  @bodyid = 'bloglist'
  html = template('header').result
  html << template('bloglist').result
  html << template('footer').result
  File.open('site/blog', 'w') {|f| f.puts html }


  ########## WRITE BLOG RSS/ATOM FEED
  feed = Atom::Feed.new do |f|
    f.id = 'http://sivers.org/en.atom'
    f.title = 'Derek Sivers'
    f.links << Atom::Link.new(:href => 'http://sivers.org/')
    f.updated = DateTime.now.to_s
    f.authors << Atom::Person.new(:name => 'Derek Sivers')
    @blogs[0,20].each do |r|
      f.entries << Atom::Entry.new do |e|
	e.id = 'http://sivers.org/' + r[:url]
	e.published = DateTime.parse(r[:date]).to_s
	e.updated = e.published
	e.title = r[:title]
	e.links << Atom::Link.new(:href => 'http://sivers.org/' + r[:url])
	e.content = Atom::Content::Html.new(r[:html])
      end
    end
  end
  File.open('site/en.atom', 'w') {|f| f.puts feed.to_xml }


  ########## READ, PARSE, AND WRITE PRESENTATIONS
  @presentations = []
  Dir['content/presentations/20*'].each do |infile|

    # PARSE. Filename: yyyy-mm-dd-uri
    /(\d{4}-\d{2})-(\S+)/.match File.basename(infile)
    @month = $1
    @url = $2
    @year = @month[0,4]
    lines = File.readlines(infile)
    /<!-- TITLE: (.+)\s+-->/.match lines.shift
    @title = $1
    /<!-- SUBTITLE: (.+)\s+-->/.match lines.shift
    @subhead = $1
    /<!-- MINUTES: ([0-9]+)\s+-->/.match lines.shift
    @minutes = $1
    @body = lines.join('')
    @pagetitle = "#{@title} | Derek Sivers"
    @bodyid = 'prez'

    # merge with templates and WRITE file
    html = template('header').result
    html << template('prez').result
    html << template('comments').result
    html << template('footer').result
    File.open("site/#{@url}", 'w') {|f| f.puts html }

    # save to array for later use in index
    @presentations << {date: @month, url: @url, title: @title, minutes: @minutes, subhead: @subhead}
  end


  ########## WRITE PRESENTATIONS INDEX PAGE
  @presentations.sort_by!{|x| x[:date]}
  @presentations.reverse!
  @pagetitle = 'Derek Sivers Presentations'
  @bodyid = 'presentations'
  html = template('header').result
  html << template('presentations').result
  html << template('footer').result
  File.open('site/presentations', 'w') {|f| f.puts html }



  ########## READ, PARSE, AND WRITE BOOK NOTES
  @books = []
  Dir['content/books/20*'].each do |infile|

    # PARSE. Filename: yyyy-mm-dd-uri
    /(\d{4}-\d{2}-\d{2})-(\S+)/.match File.basename(infile)
    @date = $1
    @url = $2
    lines = File.readlines(infile)
    /^TITLE: (.+)$/.match lines.shift
    @title = $1
    /^ISBN: (\w+)$/.match lines.shift
    @isbn = $1
    /^RATING: (\d+)$/.match lines.shift
    @rating = $1
    /^SUMMARY: (.+)$/.match lines.shift
    @summary = $1
    lines.shift  # the line that says 'NOTES:'
    @notes = lines.join('').gsub("\n", "<br>\n")
    @pagetitle = "#{@title} | Derek Sivers"
    @bodyid = 'onebook'

    # merge with templates and WRITE file
    html = template('header').result
    html << template('book').result
    html << template('footer').result
    File.open("site/book/#{@url}", 'w') {|f| f.puts html }

    # save to array for later use in index and home page
    @books << {date: @date, url: @url, title: @title, isbn: @isbn, rating: @rating, summary: @summary}
  end


  ########## WRITE BOOKS INDEX PAGE
  @books.sort_by!{|x| '%02d%s' % [x[:rating], x[:date]]}
  @books.reverse!
  @pagetitle = 'BOOKS | Derek Sivers'
  @bodyid = 'booklist'
  html = template('header').result
  html << template('booklist').result
  html << template('footer').result
  File.open('site/book/home', 'w') {|f| f.puts html }



  ########## READ AND PARSE TWEETS
  @tweets = []
  Dir['content/tweets/20*'].sort.each do |infile|

    # PARSE. Filename: yyyy-mm-dd-##  (a at end means favorite)
    /^(\d{4}-\d{2}-\d{2})/.match File.basename(infile)
    date = $1
    d = Date.parse(date)
    tweet = File.read(infile).strip.autolink

    # save to array for later use in index and home page
    @tweets << {date: date, show_date: d.strftime('%B %-d'), show_year: d.strftime('%B %-d, %Y'), tweet: tweet}
  end


  ########## WRITE TWEETS INDEX PAGE
  @tweets.reverse!
  @pagetitle = 'Derek Sivers Tweets'
  @bodyid = 'tweets'
  html = template('header').result
  html << template('tweets').result
  html << template('footer').result
  File.open('site/tweets', 'w') {|f| f.puts html }


  ########## WRITE HOME PAGE
  @new_blogs = @blogs[0,6]
  @new_tweets = @tweets[0,6]
  @pagetitle = 'Derek Sivers'
  @bodyid = 'home'
  html = template('header').result
  html << template('home').result
  html << template('footer').result
  File.open('site/home', 'w') {|f| f.puts html }


  ########## READ, PARSE, WRITE STATIC PAGES
  Dir['content/pages/*'].each do |infile|

    # PARSE. Filename: uri
    @uri = @bodyid = File.basename(infile)
    lines = File.readlines(infile)
    /<!--\s+(.+)\s+-->/.match lines.shift
    @title = $1
    body = lines.join('')
    @pagetitle = "#{@title} | Derek Sivers"

    # merge with templates and WRITE file
    html = template('header').result
    html << body
    html << template('footer').result
    File.open("site/#{@uri}", 'w') {|f| f.puts html }
  end
end   # task :make

desc 'Run all tests in test/test-*.rb'
task :test do
  Dir['test/test-*.rb'].each do |f|
    cmd = "/usr/bin/ruby #{f}"
    puts "\n#########: #{cmd}"
    system cmd
  end
end

desc 'irb with models'
task :console do
  sh 'irb -r ./models.rb'
end

desc 'make a new tweet'
task :tweet do
  filename = Time.now.strftime('%Y-%m-%d-00')
  system "vi content/tweets/#{filename}"
end

desc 'rarely-used: write translated blog posts to HTML files'
task :translated, :lang do |lang|
  require 'sequel'
  DB = Sequel.postgres('sivers', user: 'sivers')
  DB[:posts].where(lang: lang).each do |p|
    @date = p[:created_at].to_s
    @url = p[:uri]
    @year = @date[0,4]
    @title = p[:subject]
    @body = p[:html]
    @pagetitle = "#{@title} | Derek Sivers"
    @bodyid = 'oneblog'
    # merge with templates and WRITE file
    html = template('header-standalone').result
    html << template('blog').result
    html << template('footer').result
    File.open("site/#{lang}/#{@url}.html", 'w') {|f| f.puts html }
  end
end

task :default => [:make]

