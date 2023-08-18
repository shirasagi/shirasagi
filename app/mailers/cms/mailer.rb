class Cms::Mailer < ApplicationMailer
  def expiration_page_notice(site, group, pages)
    return if group.contact_email.blank?

    @site = site
    @pages = pages
    mail(
      from: site.sender_address,
      to: "#{group.section_name} <#{group.contact_email}>",
      subject: site.page_expiration_mail_subject.presence || I18n.t("cms.page_expiration_mail.default_subject")
    )
  end
end
