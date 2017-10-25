module Webmail::MailHelper
  def searched_label(params)
    return nil if params.blank?

    single_keys = %w(unseen flagged)
    h = params.map do |key, val|
      if single_keys.include?(key)
        Webmail::Mail.t(key)
      else
        val.present? ? "#{Webmail::Mail.t(key)}: #{val}" : nil
      end
    end.compact

    h.present? ? h.join(', ') : nil
  end

  def account_options(path_helper)
    @cur_user.imap_settings.map.with_index { |setting, i| [ setting.address, send(path_helper, i) ] }
  end
end
