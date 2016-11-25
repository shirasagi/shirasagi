class Jmaxml::Action::SendMail < Jmaxml::Action::Base
  include Jmaxml::Addon::Sender
  include Jmaxml::Addon::Recipient

  def execute(page, context)
    mailer = context.type.mailer
    mail = mailer.create(page, context, self)
    mail.from = full_sender_email
    recipient_emails.each do |to|
      mail.to = to
      mail.deliver_now
    end
  end
end
