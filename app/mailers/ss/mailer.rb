class SS::Mailer < ApplicationMailer
  def new_message(args)
    mail(args)
  end
end
