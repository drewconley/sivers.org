require 'erb'

def template(name)
  ERB.new(File.read("templates/#{name}.erb"))
end

Dir['blog/*'].each do |d|
  /(\d{4}-\d{2}-\d{2})-(\S+)/.match File.basename(d)
  @date = $1
  @year = @date[0,4]
  @url = $2
  lines = File.readlines(d)
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
end

