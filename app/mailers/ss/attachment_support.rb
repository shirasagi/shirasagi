module SS::AttachmentSupport
  extend ActiveSupport::Concern

  DEFAULT_BINARY_TYPE = SS::MimeType::DEFAULT_MIME_TYPE

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
    elsif content_type == "message/rfc822"
      #
      # There are some bugs in standard mail gem.
      # To prevent from mail corruption, a part must be manually encoded.
      #
      encoded = ::Mail::Encodings.decode_encode(file.name, :encode)
      part[:mime_type] = "#{DEFAULT_BINARY_TYPE}; filename=\"#{encoded}\""
    else
      #
      # There are some inconvenient manner for binary attachment in standard mail gem.
      # So, attachment is encoded manually
      #
      encoded = ::Mail::Encodings.decode_encode(file.name, :encode)

      part[:mime_type] = "#{content_type}; filename=\"#{encoded}\""
    end
    part[:transfer_encoding] = "base64"
    part[:body] = ::Base64.encode64(part[:body])

    attachments[file.name] = part
  end
end
