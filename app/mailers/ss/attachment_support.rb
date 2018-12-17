module SS::AttachmentSupport
  extend ActiveSupport::Concern

  def add_attachment_file(file)
    part = { body: file.read }
    content_type = ::SS::MimeType.find(file.name, nil)
    if content_type.start_with?("text/")
      #
      # There are some bugs in standard mail gem.
      # To prevent from text corruption, a part must be manually encoded.
      #
      enc = ::NKF.guess(part[:body])
      part[:mime_type] = "#{content_type}; charset=\"#{enc}\""
      part[:transfer_encoding] = "base64"
      part[:body] = ::Base64.encode64(part[:body])
    end

    attachments[file.name] = part
  end
end
