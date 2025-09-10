class MailPage::ImportJob < Cms::ApplicationJob
  queue_as :external

  def put_log(message)
    Rails.logger.warn(message)
  end

  def perform(file)
    mail = ::Mail.new(Fs::binread(file))
    from = mail.from[0]
    if mail.to.size == 1
      to = mail.to[0]
    else
      to = mail["X-Original-To"].value rescue nil
      raise "failed to extract X-Original-To" if to.blank?
    end
    body = mail.text_part ? mail.text_part.decoded : mail.decoded

    put_log("from: " + from)
    put_log("to: " + to)
    put_log("subject: " + mail.subject)
    put_log("body: \n" + body)

    from_domain = from.sub(/^.+@/, "")
    to_domain = to.sub(/^.+@/, "")
    nodes = MailPage::Node::Page.site(site)
      .in(mail_page_from_conditions: /^(#{from}|#{from_domain})$/)
      .in(mail_page_to_conditions: /^(#{to}|#{to_domain})$/)

    nodes.each do |node|
      node.create_page_from_mail(mail)
      put_log("imported: #{node.name}(#{node.filename})")

      if node.urgency_enabled?
        node.urgency_switch_layout
        put_log("switch layout")
      end
    end
  end
end
