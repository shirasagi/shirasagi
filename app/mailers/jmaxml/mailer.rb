class Jmaxml::Mailer < ActionMailer::Base
  def create_mail(page, context, action)
    @page = page
    @context = context
    @action = action
    @renderer = @context.type.renderer(@page, @context)
    mail
  end
end
