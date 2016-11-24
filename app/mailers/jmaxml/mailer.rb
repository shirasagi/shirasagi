class Jmaxml::Mailer < ActionMailer::Base
  def create_mail(opts)
    mail(from: opts[:from], to: opts[:to], subject: opts[:subject], body: opts[:body])
  end
end
