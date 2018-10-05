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
    @cur_user.imap_settings.map.with_index { |setting, i| [ setting.name, send(path_helper, i) ] }
  end

  def group_options(path_helper)
    return [] if !@cur_user.webmail_permitted_all?(:use_webmail_group_imap_setting)

    @cur_user.groups
             .select { |group| group.imap_setting.try(:name).present? }
             .map { |group| [group.imap_setting.name, send(path_helper, webmail_mode: :group, account: group.id)] }
  end

  def webmail_other_account?(path_helper)
    return true if @cur_user.imap_settings.any?
    return false if !@cur_user.webmail_permitted_all?(:use_webmail_group_imap_setting)

    @cur_user.groups.pluck(:imap_settings).select(&:present?).any?
  end

  def webmail_other_account_select(path_helper)
    options  = account_options(path_helper) + group_options(path_helper)
    selected = send(path_helper, webmail_mode: @webmail_mode || :account, account: params[:account])

    options.unshift([nil, send(path_helper, @cur_user.imap_default_index)]) if account_options(path_helper).blank?

    select_tag(
      :select_account,
      options_for_select(options, selected),
      class: "webmail-select-account"
    ).html_safe
  end
end
