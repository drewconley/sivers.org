#!/usr/bin/env ruby
require 'pg'
DB = PG::Connection.new(dbname: 'd50b', user: 'd50b')

def li(row)
	'<li id="comment-%d"><cite>%s (%s) <a href="#comment-%d">#</a></cite><p>%s</p></li>' %
		[row['id'], row['name'], row['created_at'], row['id'],
	 		(row['html'].gsub(%r{(https?://\S+)}, '<a href="\1">\1</a>')).gsub("\n", '<br>')]
end

def ol(res)
	return '' if res.ntuples == 0
	res.inject('<ol>') {|html, row| html += li(row) ; html} + '</ol>'
end

def qry(uri)
	ol DB.exec_params("SELECT id, created_at, name, html FROM sivers.comments WHERE uri=$1 ORDER BY id", [uri])
end

dirname = File.expand_path('../../sivers_comments', __FILE__) << '/'
Dir.mkdir(dirname, 0755) unless Dir.exist?(dirname)

# first write them all
DB.exec("SELECT DISTINCT(uri) FROM sivers.comments").column_values(0).each do |uri|
	File.open(dirname + uri, 'w') do |f|
		f.puts qry(uri)
	end
end

# now listen and wait
DB.exec("LISTEN comments_changed")

while true do
	DB.wait_for_notify do |event, pid, uri|
		File.open(dirname + uri, 'w') do |f|
			f.puts qry(uri)
		end
	end
end


