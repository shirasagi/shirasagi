class Gws::Report::Mailer < ActionMailer::Base
  def publish_mail(item, opts)
    @item = item
    mail(opts)
  end

  alias depublish_mail publish_mail
end
