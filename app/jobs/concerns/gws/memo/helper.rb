module Gws::Memo::Helper
  include SS::ExportHelper

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
    if user.email.present?
      "#{user.name} <#{user.email}>"
    else
      user.name
    end
  end

  def gen_message_id(data)
    @domain_for_message_id ||= site.canonical_domain.presence || SS.config.gws.canonical_domain.presence || "localhost.local"
    "<#{data["id"].to_s.presence || data["_id"].to_s.presence || SecureRandom.uuid}@#{@domain_for_message_id}>"
  end

  def write_body_to_eml(file, data)
    if data["format"] == "html"
      content_type = "text/html"
      sanitized_html = sanitize_content(data["html"])
      base64 = Mail::Encodings::Base64.encode(sanitized_html)
    else
      content_type = "text/plain"
      sanitized_text = sanitize_content(data["text"])
      base64 = Mail::Encodings::Base64.encode(sanitized_text)
    end

    file.puts "Content-Type: #{content_type}; charset=UTF-8"
    file.puts "Content-Transfer-Encoding: base64"
    file.puts ""
    file.puts base64
  end

  def sanitize_content(text)
    sanitized_content = text.gsub(/<script[^>]*>[^<]+<\/script>/i, "").
      gsub(/<style[^>]*>[^<]+<\/style>/i, "").
      gsub(/\s?style="(.*?)"/i, "")

    sanitized_content
  end
end
