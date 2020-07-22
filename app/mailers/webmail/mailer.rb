class Webmail::Mailer < ActionMailer::Base
  include SS::AttachmentSupport

  def rescue_deliver(e)
    raise e
  end

  def new_message(item)
    @item = item

    @item.size = 0
    @item.ref_files_with_data.each do |file|
      add_attachment_file(file)
      @item.size += file.size
    end

    @item.files.each do |file|
      add_attachment_file(file)
      @item.size += file.size
    end

    if @item.in_request_mdn == "1"
      dnt = Webmail::Converter.extract_address(@item.mail_headers[:from])
      headers["Disposition-Notification-To"] = dnt
    end

    mail(@item.mail_headers) do |format|
      if @item.html?
        format.html
      else
        format.text
      end
    end

    if @item.in_request_dsn == "1"
      from = Webmail::Converter.extract_address(mail.from.first)
      mail.smtp_envelope_to = (mail.to.to_a + mail.cc.to_a + mail.bcc.to_a).map do |addr|
        to = Webmail::Converter.extract_address(addr)
        "<#{to}> NOTIFY=SUCCESS,FAILURE ORCPT=rfc822;#{from}"
      end
    end

    mail
  end

  def mdn_message(item)
    require "nkf"
    @item = item

    msg = mail(
      to: item.disposition_notification_to,
      from: item.imap.email_address,
      body: ''
    )
    msg.content_type = 'multipart/report; report-type=disposition-notification'

    # part1
    part1 = Mail::Part.new
    part1.content_type = 'text/plain; iso-2022-jp'
    part1.body = NKF.nkf '-j', render_to_string

    # part2
    part2 = Mail::Part.new
    part2.content_type = 'message/disposition-notification; name=MDNPart2.txt'
    part2.content_disposition = 'inline'

    body = []
    body << "Final-Recipient: rfc822; #{item.from.first}\r\n"
    body << "Disposition: manual-action/MDN-sent-manually; displayed\r\n"
    part2.body = body.join

    # part3
    part3 = Mail::Part.new
    part3.content_type = 'text/rfc822-headers; name=MDNPart3.txt'
    part3.content_disposition = 'inline'
    part3.body = item.rfc822

    # add part
    msg.add_part part1
    msg.add_part part2
    msg.add_part part3 if part3.body

    msg
  end
end
