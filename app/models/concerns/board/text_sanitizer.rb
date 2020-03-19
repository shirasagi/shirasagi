module Board::TextSanitizer
  extend ActiveSupport::Concern

  def sanitized_text
    return "" if self.text.blank?

    helpers = ApplicationController.helpers

    ret = self.text
    ret = helpers.sanitize(ret, tags: [])
    ret = ret.strip
    ret = CGI.escapeHTML(ret)
    ret = helpers.ss_auto_link(ret, link: :urls, link_to: method(:wrap_link_to))
    ret = helpers.br(ret)
    ret
  end

  private

  def wrap_link_to(link_text, link_attributes, escape)
    url_helpers = Rails.application.routes.url_helpers

    href = link_attributes["href"]
    return link_text if href.blank? || (!href.start_with?("http://") && !href.start_with?("https://"))

    link_attributes["href"] = url_helpers.sns_redirect_path(ref: href)
    link_attributes["target"] ||= "_blank"
    link_attributes["class"] ||= "external"
    ApplicationController.helpers.content_tag(:a, link_text, link_attributes, escape)
  end
end
