class Gws::Notice::Mailer < ActionMailer::Base
  def notify_mail(site, notice, to)
    from = site.sender_address
    subject = I18n.t("gws_notification.#{Gws::Notice::Post.model_name.i18n_key}.subject", name: notice.name, default: notice.name)

    @item = notice
    mail(from: from, to: to, subject: subject) do |format|
      format.text
    end
  end
end
