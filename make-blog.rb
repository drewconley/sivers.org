require 'erb'
header_template = ERB.new(File.read('templates/header.erb'))
footer_template = ERB.new(File.read('templates/footer.erb'))

Dir['blog/*'].each do |d|
  /(\d{4}-\d{2}-\d{2})-(\S+)/.match File.basename(d)
  date = $1
  url = $2
  lines = File.readlines(d)
  /<!--\s+(.+)\s+-->/.match lines.shift
  title = $1
  body = lines.join('')

  @pagetitle = title
  @bodyid = 'oneblog'
  html = header_template.result + body + footer_template.result

  File.open("site/#{url}", 'w') {|f| f.puts html }
end

