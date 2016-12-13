class Jmaxml::Action::SendMail < Jmaxml::Action::Base
  include Jmaxml::Addon::Action::Sender
  include Jmaxml::Addon::Action::Recipient
  include Jmaxml::Addon::Action::PublishingOffice

  def execute(page, context)
    mailer = context.type.mailer
    mail = mailer.create(page, context, self)
    mail.from = full_sender_email
    recipient_emails.each do |to|
      m = mail.dup
      m.to = to
      m.deliver_now
    end
  end
end
