class Gws::Memo::Mailer < ActionMailer::Base
  def forward_mail(item, user, site, to)
    @item = item
    @cur_user = user
    @cur_site = site
    @cc_memo = @item.members.map { |item| "#{item.name} <#{item.email}>" }.join(", ")

    from = @cur_site.memo_email.presence || ActionMailer::Base.default[:from]
    subject = "[#{I18n.t("gws/memo/message.message")}]#{I18n.t("gws/memo/forward.subject")}:#{@cur_user.name}"

    @item.files.each do |file|
      attachments[file.name] = file.read
    end

    mail(from: from, to: to, subject: subject)
  end
end

