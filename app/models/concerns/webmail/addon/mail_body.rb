module Webmail::Addon
  module MailBody
    extend ActiveSupport::Concern
    extend SS::Addon

    def sanitize_html(opts = {})
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

      html = ApplicationController.helpers.sanitize_with(html, attributes: %w(data-url))
      html = html.gsub!(/<img.*?>/im, '') if opts[:remove_image]
      html
    end
  end
end
