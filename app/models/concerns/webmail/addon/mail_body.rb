module Webmail::Addon
  module MailBody
    extend ActiveSupport::Concern
    extend SS::Addon

    def sanitize_html
      html = self.html
      html = html.gsub(/<style.*?<\/style>/im, '')
      html = html.gsub(/<script.*?<\/script>/im, '')

      html = html.gsub(/(<img [^>]*)src="(.*?)"([^>]*>)/im) do |img|
        pre = $1
        src = $2
        suf = $3
        if src =~ /^cid:/
          all_parts.each do |pos, part|
            next unless part.content_id.to_s.include?(src.sub(/^cid:/, ''))
            src = "parts/#{pos}"
            break
          end
        end
        %(#{pre}data-url="#{src}"#{suf})
      end

      ApplicationController.helpers.sanitize_with(html, attributes: %w(data-url))
    end
  end
end
