class Gws::Memo::Mailer < ActionMailer::Base
  include SS::AttachmentSupport

  helper_method :format_email

  def forward_mail(item, forward_emails)
    @item = item
    @cur_user = item.user
    @cur_site = item.site
    @to = @item.sorted_to_members.map { |item| format_email(item.name, item.email) }.join(", ")
    @cc = @item.sorted_cc_members.map { |item| format_email(item.name, item.email) }.join(", ")

    from = @cur_site.sender_address
    subject = "[#{I18n.t("gws/memo/message.message")}]#{I18n.t("gws/memo/forward.subject")}:#{@cur_user.name}"

    @item.files.each do |file|
      add_attachment_file(file)
    end

    mail(from: from, bcc: forward_emails, subject: subject)
  end

  def notice_mail(notice, users, item)
    @item = item
    @cur_site = @item.try(:site) || @item.try(:cur_group) || @item.try(:_parent).try(:site)
    return false unless @cur_site.allow_send_mail?

    @users = users.select{ |user| user.use_notice_email?(@item) }
    return false unless @users.present?

    @notice = notice
    subject = @notice.subject
    @body = I18n.t("gws_notification.#{i18n_key}.mail_text", subject: subject, text: page_url)
    set_group_settings
    bcc = @users.map(&:send_notice_mail_addresses).flatten
    bcc = bcc.select{ |email| email.present? && @cur_site.email_domain_allowed?(email) }

    return false unless bcc.present?

    mail(from: @from, bcc: bcc, subject: subject, body: @body)
  end

  def set_group_settings
    @from = @cur_site.sender_address

    if signature = @cur_site.mail_signature.presence
      @body << "\r\n"
      @body << signature
    end
  end

  def i18n_key
    @item.class.model_name.i18n_key
  end

  def item_title
    title = @item.try(:topic).try(:name)
    title ||= @item.try(:schedule).try(:name)
    title ||= @item.try(:_parent).try(:name)
    title ||= @item.try(:name)
    title
  end

  def page_url
    scheme = @cur_site.canonical_scheme.presence || SS.config.gws.canonical_scheme.presence || "http"
    domain = @cur_site.canonical_domain.presence || SS.config.gws.canonical_domain

    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_memo_notice_url(protocol: scheme, host: domain, site: @cur_site.id, id: @notice.id)
  end

  def format_email(name, email)
    if name.present? && email.present?
      "#{name} <#{email}>"
    elsif name.present?
      name.to_s
    else
      email.to_s
    end
  end
end
