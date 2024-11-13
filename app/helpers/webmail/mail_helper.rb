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
    @cur_user.webmail_user.imap_settings.map.with_index { |setting, i| [ setting.name, send(path_helper, i) ] }
  end

  def group_options(path_helper)
    return [] if !@cur_user.webmail_user.webmail_permitted_all?(:use_webmail_group_imap_setting)

    groups = @cur_user.webmail_user.groups.exists(imap_settings: true)
    groups = groups.select do |group|
      imap_setting = group.imap_setting
      imap_setting.present? && imap_setting.imap_account.present? && imap_setting.imap_password.present?
    end
    groups.map { |group| [group.imap_setting.name, send(path_helper, webmail_mode: :group, account: group.id)] }
  end

  def webmail_other_account?(path_helper)
    return true if @cur_user.webmail_user.imap_settings.any?
    return false if !@cur_user.webmail_user.webmail_permitted_all?(:use_webmail_group_imap_setting)

    @cur_user.webmail_user.groups.pluck(:imap_settings).select(&:present?).any?
  end

  def webmail_other_account_select(path_helper)
    account_options = account_options(path_helper)
    group_options = group_options(path_helper)
    selected = send(path_helper, webmail_mode: @webmail_mode || :account, account: params[:account])

    all_options = account_options + group_options
    all_options.unshift([nil, send(path_helper, @cur_user.webmail_user.imap_default_index)]) if account_options.blank?
    option_tags = options_for_select(all_options, selected)

    opts = { class: "webmail-select-account" }
    opts[:include_blank] = true if !option_tags.include?("selected")

    select_tag(
      :select_account,
      option_tags,
      opts
    ).html_safe
  end

  def link_to_webmail_account_config_path(options = {})
    options[:account] ||= params[:account]
    options[:account] ||= @cur_user.webmail_user.imap_default_index
    options[:webmail_mode] ||= @webmail_mode.to_s

    label = options.delete(:label)
    path_proc = options.delete(:path_proc)
    group_imap_permission = options.delete(:group_imap_permission)

    return link_to(label, path_proc.call(options)) if @webmail_mode == :account || !group_imap_permission
    return link_to(label, path_proc.call(options)) if @cur_user.webmail_user.webmail_permitted_any?(group_imap_permission)
    nil
  end

  def link_to_webmail_mailboxes_path(options = {})
    options[:label] = t('mongoid.models.webmail/mailbox')
    options[:path_proc] = proc { |options| webmail_mailboxes_path(options) }

    link_to_webmail_account_config_path(options)
  end

  def link_to_webmail_signatures_path(options = {})
    options[:label] = t('mongoid.models.webmail/signature')
    options[:path_proc] = proc { |options| webmail_signatures_path(options) }

    link_to_webmail_account_config_path(options)
  end

  def link_to_webmail_filters_path(options = {})
    options[:label] = t('mongoid.models.webmail/filter')
    options[:path_proc] = proc { |options| webmail_filters_path(options) }

    link_to_webmail_account_config_path(options)
  end

  def link_to_webmail_cache_setting_path(options = {})
    options[:label] = t('webmail.settings.cache')
    options[:path_proc] = proc { |options| webmail_cache_setting_path(options) }

    link_to_webmail_account_config_path(options)
  end

  def link_to_new_window(name = nil, options = nil, html_options = nil, &block)
    html_options ||= {}
    if html_options[:class]
      css_classes = Array(html_options[:class])
      css_classes.map! { |css_class| css_class.split }
      css_classes.flatten!
      css_classes.map!(&:strip)
      unless css_classes.include?("ss-open-in-new-window")
        css_classes << "ss-open-in-new-window"
      end
      html_options[:class] = css_classes
    else
      html_options[:class] = "ss-open-in-new-window"
    end

    html_options[:data] ||= {}
    unless html_options[:data][:width]
      html_options[:data][:width] = SS.config.webmail.mail_edit_screen_width
    end

    link_to(name, options, html_options, &block)
  end

  def email_addresses_to_link(text)
    # ref. # https://github.com/tenderlove/rails_autolink/blob/v1.1.6/lib/rails_autolink/helpers.rb#L81-L82
    #
    # AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&'*\/=?^`{|}~+-]/
    # AUTO_EMAIL_RE = /[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+/
    email_regex = /[\w.!#$%+-]\.?#{/[\w.!#$%&'*\/=?^`{|}~+-]/}*@[\w-]+(?:\.[\w-]+)+/

    text.gsub(email_regex) do |address|
      link_to address, new_webmail_mail_path(mailbox: @mailbox, item: { to: address })
    end.html_safe
  end

  def move_to_prev_tag
    prev_path = @prev_uid ? url_for(action: :show, id: @prev_uid) : "#"
    css_classes = %w(prev)
    unless @prev_uid
      css_classes << "inactive"
    end

    tag.div(class: css_classes) do
      link_to(prev_path, title: t('ss.links.prev')) do
        md_icons.outlined("arrow_circle_left")
      end
    end
  end

  def move_to_next_tag
    next_path = @next_uid ? url_for(action: :show, id: @next_uid) : "#"
    css_classes = %w(next)
    unless @next_uid
      css_classes << "inactive"
    end

    tag.div(class: css_classes) do
      link_to(next_path, title: t('gws/memo/message.links.next')) do
        md_icons.outlined("arrow_circle_right")
      end
    end
  end
end
