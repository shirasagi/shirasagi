module Webmail::MailHelper
  def searched_label(params)
    return nil if params.blank?

    h = params.map do |key, val|
      val.present? ? "#{Webmail::Mail.t(key)}: #{val}" : nil
    end.compact

    h.present? ? h.join(', ') : nil
  end
end
