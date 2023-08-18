module Inquiry::MailerHelper
  def convert_to_lines(str, maxsize = 400)
    return '' unless str.is_a?(String)
    str.scan(/.{#{maxsize}}|.*\R|.+$/).map { |s| s.chomp }.join("\n")
  end
end
