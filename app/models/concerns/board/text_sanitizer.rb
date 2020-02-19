module Board::TextSanitizer
  extend ActiveSupport::Concern

  def sanitized_text
    return "" if self.text.blank?

    helpers = ApplicationController.helpers

    ret = self.text
    ret = helpers.sanitize(ret, tags: [])
    ret = ret.strip
    ret = CGI.escapeHTML(ret)
    ret = helpers.auto_link(ret, link: :urls)
    ret = helpers.br(ret)
    ret
  end
end
