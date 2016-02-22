class Sys::Mailer < ActionMailer::Base
  def test_mail(args)
     mail args
  end
end
