class Webmail::Mailer < ActionMailer::Base
  def new_message(item)
    @item = item
    user = item.imap.user

    params = {
      from: "#{user.name} <#{user.email}>",
      to: item.to,
      cc: item.cc,
      bcc: item.bcc,
      subject: item.subject
    }

    mail(params) do |format|
      if item.html?
        format.html
      else
        format.text
      end
    end
  end
end
