module Gws::Memo::Helper

  private

  def file_attributes(file)
    data = file.attributes
    data["base64"] = Base64.strict_encode64(::File.binread(file.path))
    data
  end

  def user_attributes(user)
    user.attributes.select { |k, v| %w(_id name).include?(k) }
  end

  def user_name_email(user)
    Gws::Memo.rfc2822_mailbox(site: site, name: user.name, email: user.email, sub: "users")
  end

  def gen_message_id(data)
    @domain_for_message_id ||= site.canonical_domain.presence || SS.config.gws.canonical_domain.presence || "localhost.local"
    "<#{data["id"].to_s.presence || data["_id"].to_s.presence || SecureRandom.uuid}@#{@domain_for_message_id}>"
  end

  def serialize_body(data)
    if data["format"] == "html"
      content_type = "text/html"
      body = sanitize_content(data["html"])
    else
      content_type = "text/plain"
      body = sanitize_content(data["text"])
    end

    header = {
      "Content-Type" => "#{content_type}; charset=UTF-8",
      "Content-Transfer-Encoding" => "base64"
    }

    [ header, StringIO.new(body) ]
  end

  def write_body_to_eml(file, data)
    header, body = serialize_body(data)
    header.each do |key, value|
      file.write "#{key}: #{value}\r\n"
    end
    file.write "\r\n"
    file.write Mail::Encodings::Base64.encode(body.read)
    file.write "\r\n"
  end

  def sanitize_content(text)
    return text if text.blank?
    ApplicationController.helpers.sanitize(text)
  end
end
