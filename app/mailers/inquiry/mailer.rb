class Inquiry::Mailer < ApplicationMailer
  helper Inquiry::MailerHelper

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

    from = Cms.sender_address(node, site)
    mail(from: from, to: notice_email, message_id: Cms.generate_message_id(@node.cur_site || @node.site))
  end

  def reply_mail(site, node, answer)
    @answer = answer
    @subject = node.reply_subject
    @node = node
    reply_email_address = nil
    from = Cms.sender_address(node, site)

    answer.data.each do |data|
      if data.column.input_type == "email_field"
        reply_email_address = data.value
        break
      end
    end
    return nil if reply_email_address.blank?
    mail(from: from, to: reply_email_address, message_id: Cms.generate_message_id(@node.cur_site || @node.site))
  end
end
