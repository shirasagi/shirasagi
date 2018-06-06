class MailPage::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.warn(message)
  end

  def perform(file)
    mail = ::Mail.new(Fs::binread(file))
    from = mail.from[0]
    to = mail.to[0]
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
    end

    Fs.rm_rf file
  end
end
