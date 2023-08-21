class Gws::Share::Mailer < ApplicationMailer
  def compressed_mail(site, user, compressor)
    @item = compressor
    @user = user

    from = site.sender_address
    to = format_email(@user)
    subject = I18n.t("gws/share.mailers.compressed.subject")

    mail(from: from, to: to, subject: subject, message_id: Gws.generate_message_id(site))
  end

  def format_email(user)
    return nil if user.email.blank?

    if user.name.present?
      "#{user.name} <#{user.email}>"
    else
      user.email
    end
  end
end
