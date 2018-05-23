class Inquiry::Mailer < ActionMailer::Base
  add_template_helper(Inquiry::MailerHelper)

  def notify_mail(site, node, answer, notice_email)
    @node = node
    @answer = answer
    @answer_url = ::File.join(
      site.mypage_full_url,
      Rails.application.routes.url_helpers.inquiry_answer_path(site: site.id, cid: node.id, id: answer.id)
    )
    @subject = "[#{I18n.t('inquiry.notify')}]#{node.name} - #{site.name}"

    @answer_data = []
    if @node.notice_content == "include_answers"
      @answer.data.each do |data|
        @answer_data << "- #{data.column.name}"
        @answer_data << data.value.to_s
        @answer_data << ""
      end
      @answer_data << "- #{@answer.class.t('remote_addr')}"
      @answer_data << @answer.remote_addr
      @answer_data << ""
      @answer_data << "- #{@answer.class.t('user_agent')}"
      @answer_data << @answer.user_agent
    end
    @answer_data = @answer_data.join("\n")

    from = "#{node.from_name} <#{node.from_email}>"
    mail(from: from, to: notice_email)
  end

  def reply_mail(site, node, answer)
    @answer = answer
    @subject = node.reply_subject
    @node = node
    reply_email_address = nil
    from = "#{node.from_name} <#{node.from_email}>"

    answer.data.each do |data|
      if data.column.input_type == "email_field"
        reply_email_address = data.value
        break
      end
    end
    return nil if reply_email_address.blank?
    mail(from: from, to: reply_email_address)
  end
end
