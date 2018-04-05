module SS::MailerHelper
  def convert_to_lines(str, maxlength = 800)
    str.split(/\R/).map do |s|
      line = ""
      lines = []
      bytes_count = 0

      s.split(//).each do |c|
        bytes_count += 2
        #bytes_count += c.bytes.count
        if bytes_count > maxlength
          lines << line
          line = ""
          bytes_count = 0
        end
        line += c
      end
      lines.present? ? lines.join("\n") : s
    end.join("\n")
  end
end
