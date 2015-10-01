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

def h(str)
	ERB::Util.html_escape(str)
end

class String
	def autolink
		self.gsub(/(http\S*)/, '<a href="\1">\1</a>')
	end
end

desc "build site/ from content/ and templates/"
task :make do
	# collection of all URLs, for making Sitemap
	@urls = []

	########## READ, PARSE, AND WRITE BLOG POSTS
	@blogs = []
	removed = %w(married dd-only piracy)
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
		if removed.include? @url
			@pagetitle = 'removed'
			html = template('header').result
			html << template('bloggone').result
		else
			html = template('header').result
			html << template('blog').result
			html << template('comments').result
		end
		html << template('footer').result
		File.open("site/#{@url}", 'w') {|f| f.puts html }

		# save to array for later use in index and home page
		unless removed.include? @url
			@blogs << {date: @date, url: @url, title: @title, html: @body}
			@urls << @url
		end
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

		# PARSE. Filename: yyyy-mm-uri
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
		@urls << @url
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



	########## READ, PARSE, AND WRITE INTERVIEWS
	@interviews = []
	linkext = {'mp3' => 'audio (mp3)', 'mp4' => 'video (mp4)'}
	linkformat = '<a href="http://sivers.org/file/%s">%s</a>'
	Dir['content/interviews/20*'].each do |infile|
		# PARSE. Filename: yyyy-mm-uri - all = uri
		m = /(\d{4}-\d{2})-\S+/.match File.basename(infile)
		@month = m[1]
		@url = m[0]
		@year = @month[0,4]
		lines = File.readlines(infile)
		# required headers:
		/<!-- TITLE: (.+) -->/.match lines.shift
		@title = $1
		/<!-- SUBTITLE: (.+) -->/.match lines.shift
		@subhead = $1
		# optional headers:
		@link = false
		@downloads = []
		line = lines.shift
		until line.strip == '' do
			m = /<!-- ([A-Z]+): (.+) -->/.match line
			case m[1]
			when 'URL' then @link = m[2]
			when 'DOWNLOAD' then @downloads << (linkformat % [m[2], linkext[m[2][-3..-1]]])
			end
			line = lines.shift
		end
		@body = lines.join('')
		@pagetitle = "Derek Sivers INTERVIEW: #{@title}"
		@bodyid = 'interview'

		# merge with templates and WRITE file
		html = template('header').result
		html << template('interview').result
		html << template('comments').result
		html << template('footer').result
		File.open("site/#{@url}", 'w') {|f| f.puts html }

		# save to array for later use in index
		@interviews << {date: @month, url: @url, title: @title, subhead: @subhead}
		@urls << @url
	end


	########## WRITE INTERVIEWS INDEX PAGE
	@interviews.sort_by!{|x| x[:date]}
	@interviews.reverse!
	@pagetitle = 'Derek Sivers Interviews'
	@bodyid = 'interviews'
	html = template('header').result
	html << template('interviews').result
	html << template('footer').result
	File.open('site/interviews', 'w') {|f| f.puts html }


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
		lines.shift	# the line that says 'NOTES:'
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
		@urls << @url
	end


	########## WRITE BOOKS INDEX PAGE
	# sivers.org/book = top rated at top
	@books.sort_by!{|x| '%02d%s%s' % [x[:rating], x[:date], x[:url]]}
	@books.reverse!
	@pagetitle = 'BOOKS | Derek Sivers'
	@bodyid = 'booklist'
	html = template('header').result
	html << template('booklist').result
	html << template('footer').result
	File.open('site/book/home', 'w') {|f| f.puts html }
	# sivers.org/book/new = newest at top
	@books.sort_by!{|x| '%s%02d%s' % [x[:date], x[:rating], x[:url]]}
	@books.reverse!
	html = template('header').result
	html << template('booklist').result
	html << template('footer').result
	File.open('site/book/new', 'w') {|f| f.puts html }



	########## READ AND PARSE TWEETS
	@tweets = []
	Dir['content/tweets/20*'].sort.each do |infile|

		# PARSE. Filename: yyyy-mm-dd-##	(a at end means favorite)
		/^(\d{4}-\d{2}-\d{2})/.match File.basename(infile)
		date = $1
		d = Date.parse(date)
		tweet = ERB::Util.html_escape(File.read(infile).strip).autolink

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
		@urls << @uri
	end

	########## SITEMAP
	today = Time.new.strftime('%Y-%m-%d')
	xml = <<XML
<?xml version="1.0" encoding="utf-8" ?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://sivers.org/</loc><lastmod>#{today}</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>
<url><loc>http://sivers.org/blog</loc><lastmod>#{today}</lastmod><changefreq>daily</changefreq><priority>0.9</priority></url>
<url><loc>http://sivers.org/tweets</loc><lastmod>#{today}</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>
<url><loc>http://sivers.org/book</loc><lastmod>#{today}</lastmod><changefreq>weekly</changefreq><priority>0.7</priority></url>
<url><loc>http://sivers.org/presentations</loc><lastmod>#{today}</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>
<url><loc>http://sivers.org/interviews</loc><lastmod>#{today}</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>
XML
	@urls.each do |u|
		xml << "<url><loc>http://sivers.org/#{u}</loc></url>\n"
	end
	xml << '</urlset>'
	File.open('site/sitemap.xml', 'w') {|f| f.puts xml }
 
end	 # task :make

desc 'make a new tweet'
task :tweet do
	filename = Time.now.strftime('%Y-%m-%d-00')
	system "vi content/tweets/#{filename}"
end

task :default => [:make]

