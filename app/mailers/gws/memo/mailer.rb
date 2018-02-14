class Gws::Memo::Mailer < ActionMailer::Base
  def forward_mail(item, forward_emails)
    @item = item
    @cur_user = item.user
    @cur_site = item.site
    @to = @item.sorted_to_members.map { |item| "#{item.name} <#{item.email}>" }.join(", ")
    @cc = @item.sorted_cc_members.map { |item| "#{item.name} <#{item.email}>" }.join(", ")

    from = @cur_site.memo_email.presence || ActionMailer::Base.default[:from]
    subject = "[#{I18n.t("gws/memo/message.message")}]#{I18n.t("gws/memo/forward.subject")}:#{@cur_user.name}"

    @item.files.each do |file|
      attachments[file.name] = file.read
    end

    mail(from: from, bcc: forward_emails, subject: subject)
  end
end

