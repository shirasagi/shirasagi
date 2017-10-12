module Webmail::MailHelper
  def searched_label(params)
    return nil if params.blank?

    h = params.map do |key, val|
      val.present? ? "#{Webmail::Mail.t(key)}: #{val}" : nil
    end.compact

    h.present? ? h.join(', ') : nil
  end

  def account_options(path_helper)
    @cur_user.imap_settings.map.with_index { |setting, i| [ setting.imap_account, send(path_helper, i) ] }
  end
end
