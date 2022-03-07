class Cms::SyntaxChecker::UrlSchemeChecker
  include Cms::SyntaxChecker::Base

  ATTRIBUTES = %w(href src).freeze

  def check(context, id, idx, raw_html, fragment)
    ATTRIBUTES.each do |attr|
      fragment.css("[#{attr}]").each do |node|
        attr_value = node[attr]
        next if attr_value.blank?
        next unless invalid_scheme?(attr_value)

        context.errors << {
          id: id,
          idx: idx,
          code: Cms::SyntaxChecker::Base.outer_html_summary(node),
          msg: I18n.t('errors.messages.invalid_url_scheme'),
          detail: I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme'),
        }
      end
    end
  end

  private

  def invalid_scheme?(url_like)
    url = Addressable::URI.parse(url_like) rescue nil
    return false if !url

    scheme = url.scheme
    return false if scheme.blank?

    scheme = scheme.downcase
    !%w(http https).include?(scheme)
  end
end
