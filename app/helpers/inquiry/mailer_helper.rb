module Inquiry::MailerHelper
  def convert_to_lines(str, maxsize = 400)
    str.scan(/.{#{maxsize}}|.*\R|.+$/).map { |s| s.chomp }.join("\n")
  end
end
