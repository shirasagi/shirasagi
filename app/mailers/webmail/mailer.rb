class Webmail::Mailer < ActionMailer::Base
  def new_message(item)
    @item = item

    @item.ref_files_with_data.each do |file|
      attachments[file.name] = file.read
    end

    @item.files.each do |file|
      attachments[file.name] = file.read
    end

    mail(@item.mail_headers) do |format|
      if @item.html?
        format.html
      else
        format.text
      end
    end

    if item.in_request_dsn == "1"
      from = Webmail::Converter.extract_address(mail.from.first)
      mail.smtp_envelope_to = (mail.to.to_a + mail.cc.to_a + mail.bcc.to_a).map do |addr|
        to = Webmail::Converter.extract_address(addr)
        "<#{to}> NOTIFY=SUCCESS,FAILURE ORCPT=rfc822;#{from}"
      end
    end

    mail
  end
end
