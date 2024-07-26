class Cms::Mailer < ApplicationMailer
  def expiration_page_notice(site, group, pages)
    return if group.contact_email.blank?

    @site = site
    @pages = pages
    mail(
      from: site.sender_address,
      to: "#{group.section_name} <#{group.contact_email}>",
      subject: site.page_expiration_mail_subject.presence || I18n.t("cms.page_expiration_mail.default_subject"))
  end

  def link_errors(site, to, errors)
    if site.check_links_message_format == "csv"
      body = "[#{errors.size} errors]\n"
      if errors.size > 0
        body += "error details are in the attached csv\n"
        attachments["errors.csv"] = errors.to_csv
      end
    else
      body = errors.to_message
    end

    sender_address = site.sender_address
    sender_address = site.check_links_default_sender_address if sender_address == SS.config.mail.default_from
    mail(
      from: sender_address,
      to: to,
      subject: "[#{site.name}] Link Check: #{errors.size} errors",
      body: body,
      message_id: Cms.generate_message_id(site))
  end
end
