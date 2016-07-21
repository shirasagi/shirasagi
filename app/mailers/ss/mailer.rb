class SS::Mailer < ActionMailer::Base
  def new_message(args)
     mail(args)
  end
end
