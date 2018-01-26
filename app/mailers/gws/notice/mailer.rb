class Gws::Notice::Mailer < ActionMailer::Base
  def notify_mail(site, notice, to)
    from = from_email(site).presence || ActionMailer::Base.default[:from]
    subject = I18n.t("gws_notification.#{Gws::Notice.model_name.i18n_key}.subject", name: notice.name, default: notice.name)

    @item = notice
    mail(from: from, to: to, subject: subject) do |format|
      format.text
    end
  end

  private

  def from_email(site)
    return if site.sender_email.blank?

    if site.sender_name.present?
      "#{site.sender_name} <#{site.sender_email}>"
    else
      site.sender_email
    end
  end
end
