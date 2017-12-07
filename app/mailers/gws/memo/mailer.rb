class Gws::Memo::Mailer < ActionMailer::Base
  def forward_mail(item, user)
    @item = item
    @cur_user = user
    from = "noreply@example.com"
    to = "jouhou_tesuto_11@dockernet.co.lg.jp"
    subject = "[メッセージ]送信者:#{@cur_user.name}"

    mail(from: from, to: to, subject: subject)
  end
end

