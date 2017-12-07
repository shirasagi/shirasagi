class Gws::Memo::Mailer < ActionMailer::Base
  def forward_mail(item, user, site)
    @item = item
    @cur_user = user
    @cur_site = site
    @cc_memo = []
    @item.member_ids.each do |member_id|
      @cc_memo << Gws::User.site(@cur_site).where(id: member_id).pluck(:name, :email).first
    end
    @cc_memo.map do |item|
      item[1] = "<#{item[1]}>"
      item[0] = item.join(" ")
      item.delete_at(1)
    end
    @cc_memo = @cc_memo.flatten.join(", ")
    from = "noreply@example.com"
    to = "jouhou_tesuto_11@dockernet.co.lg.jp"
    subject = "[メッセージ]送信者:#{@cur_user.name}"

    mail(from: from, to: to, subject: subject)
  end
end

