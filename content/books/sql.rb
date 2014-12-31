File.open('books.sql', 'w') do |f|
	Dir['20*'].sort.each do |filename|
		m = /\d{4}-\d{2}-\d{2}-(.*)$/.match filename
		code = m[1]
		f.puts("INSERT INTO sivers.books(code) VALUES ('%s');" % code)
		txt = File.read(filename)
		txt = txt[((txt =~ /NOTES:/) + 6)..-1].strip
		txt.split("\n\n").each do |note|
			f.puts("INSERT INTO sivers.notes(book_code, note) VALUES ('%s', '%s');" % [code, note.strip.gsub("'", "''")])
		end
		f.puts("\n")
	end
end
