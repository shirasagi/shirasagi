class Ezine::Mailer < ActionMailer::Base
  # Deliver a verification e-mail to the entry.
  #
  # 購読申し込みに対して確認メールを配信する。
  #
  # @param [Ezine::Entry] entry
  def verification_mail(entry)
    @entry = entry

    mail from: 'noreply@example.com', to: entry.email
  end

  # Deliver Ezine::Page as an e-mail.
  #
  # Ezine::Page を E-mail として配信する。
  #
  # @param [Ezine::Page] page
  # @param [Ezine::Member, Ezine::TestMember] member
  def page_mail(page, member)
    @page = page
    @member = member

    mail from: 'noreply@example.com', to: member.email do |format|
      case member.email_type
      when "text"
        format.text
      when "html"
        format.html
      else
        # Invalid
      end
    end
  end
end
