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
  end
end
