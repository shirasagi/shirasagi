class Inquiry::Mailer < ActionMailer::Base
  public
    def notify_mail(site, node, answer)
       @answer = answer
       @subject = "[#{I18n.t('inquiry.notify')}]#{node.name} - #{site.name}"

       mail(from: node.from_email, to: node.notice_email)
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
