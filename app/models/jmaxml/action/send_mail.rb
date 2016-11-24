class Jmaxml::Action::SendMail < Jmaxml::Action::Base
  include Jmaxml::Addon::Sender
  include Jmaxml::Addon::Recipient

  def execute(page, context)
    renderer = context.type.renderer(page, context)
    title = renderer.render_title
    body = renderer.render_text
    if signature_text.present?
      body << signature_text << "\n"
    end

    recipient_emails.each do |to|
      Jmaxml::Mailer.create_mail(from: full_sender_email, to: to, subject: title, body: body).deliver_now
    end
  end
end
