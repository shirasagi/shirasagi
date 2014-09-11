# coding: utf-8
class Sys::Mailer < ActionMailer::Base
  public
    def test_mail(args)
       mail args
    end
end
