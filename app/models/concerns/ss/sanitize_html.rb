module SS::SanitizeHtml
  extend ActiveSupport::Concern

  def sanitize_html(html = nil, opts = {})
    html ||= self.html
    return html if html.blank?

    html = html.gsub(/<style.*?<\/style>/im, '')
    html = html.gsub(/<script.*?<\/script>/im, '')

    html = html.gsub(/(<img [^>]*)src="(.*?)"([^>]*>)/im) do |img|
      pre = $1
      src = $2
      suf = $3
      if src.start_with?("cid:")
        all_parts.each do |pos, part|
          next unless part.content_id.to_s.include?(src.sub(/^cid:/, ''))
          src = "parts/#{pos}"
          break
        end
      end
      %(#{pre}data-url="#{src}"#{suf})
    end

    html = ApplicationController.helpers.sanitize_with(html, attributes: %w(data-url))
    html.gsub!(/<img.*?>/im, '') if opts[:remove_image]
    html
  end
end
