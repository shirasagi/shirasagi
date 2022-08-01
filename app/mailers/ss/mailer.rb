class SS::Mailer < ApplicationMailer
  def new_message(args)
    mail(args)
  end

  def one_time_password_mail(user, email)
    @user = user
    group = user.organization.gws_group

    from = group.sender_address
    Gws::User.t(:otpw_password)
    subject = "[#{group.name}]" + Gws::User.t(:otpw_password)

    mail(from: from, to: email, subject: subject, message_id: Gws.generate_message_id(group))
  end
end
