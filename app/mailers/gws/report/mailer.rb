class Gws::Report::Mailer < ActionMailer::Base
  def publish_mail(site, item, opts = {})
    @site = site
    @item = item

    opts[:message_id] ||= Gws.generate_message_id(site)
    mail opts
  end

  alias depublish_mail publish_mail
end
