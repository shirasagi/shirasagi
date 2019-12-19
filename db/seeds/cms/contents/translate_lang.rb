puts "# translate_lang"
item = Translate::Lang.new
item.cur_site = @site
item.in_file = Fs::UploadedFile.create_from_file("translate/lang.csv")
item.import_csv
