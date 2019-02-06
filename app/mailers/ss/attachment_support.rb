module SS::AttachmentSupport
  extend ActiveSupport::Concern

  DEFAULT_BINARY_TYPE = "application/octet-stream".freeze

  def add_attachment_file(file)
    part = { body: file.read }
    content_type = ::SS::MimeType.find(file.name, DEFAULT_BINARY_TYPE)
    if content_type.start_with?("text/")
      #
      # There are some bugs in standard mail gem.
      # To prevent from text corruption, a part must be manually encoded.
      #
      enc = ::NKF.guess(part[:body])
      part[:mime_type] = "#{content_type}; charset=\"#{enc}\""
      part[:transfer_encoding] = "base64"
      part[:body] = ::Base64.encode64(part[:body])
    else
      #
      # There are some inconvenient manner for binary attachment in standard mail gem.
      # So, attachment is encoded manually
      #
      encoded = ::Mail::Encodings.decode_encode(file.name, :encode)

      part[:mime_type] = "#{content_type}; filename=\"#{encoded}\""
      part[:transfer_encoding] = "base64"
      part[:body] = ::Base64.encode64(part[:body])
    end

    attachments[file.name] = part
  end
end
