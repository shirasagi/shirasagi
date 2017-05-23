class SS::Migration20170523000000
  def change
    Fs.glob("#{SS::Site.root}/**/*.scss").each do |file|
      text = Fs.read(file)
      text_new = change_text(text)

      if text != text_new
        puts "modify #{file} # compass-mixins"
        Fs.write(file, text_new)
      end
    end
  end

  def change_text(text)
    text.gsub(/^@import +"compass\//).with_index do |str, idx|
      str = "//#{str}"
      str = %(@import "compass-mixins/lib/compass";\n) + str if idx == 0
      str
    end
  end
end
