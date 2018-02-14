class Gws::Share::Mailer < ActionMailer::Base
  def compressed_mail(user, compressor)
    @item = compressor
    @user = user

    from = ActionMailer::Base.default[:from]
    to = format_email(@user)
    subject = I18n.t("gws/share.mailers.compressed.subject",)

    mail(from: from, to: to, subject: subject)
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
