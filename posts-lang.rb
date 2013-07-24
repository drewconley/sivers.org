require 'erb'
require 'date'
require 'sequel'

def template(name)
  ERB.new(File.read("templates/#{name}.erb"))
end

lang = 'pt'
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
