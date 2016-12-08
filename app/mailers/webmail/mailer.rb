class Webmail::Mailer < ActionMailer::Base
  def new_message(item)
    @item = item

    @item.files.each do |file|
      attachments[file.name] = file.read
    end

    mail(@item.mail_attributes) do |format|
      if @item.html?
        format.html
      else
        format.text
      end
    end
  end
end
