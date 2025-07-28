class Cms::SyntaxChecker::UrlSchemeChecker
  include Cms::SyntaxChecker::Base

  ATTRIBUTES = %w(href src).freeze

  def check(context, id, idx, raw_html, fragment)
    attributes_to_check = context.cur_site.syntax_checker_url_scheme_attributes.presence || ATTRIBUTES
    shemes_to_allow = context.cur_site.syntax_checker_url_scheme_schemes.presence || %w(http https)

    attributes_to_check.each do |attr|
      fragment.css("[#{attr}]").each do |node|
        attr_value = node[attr]
        next if attr_value.blank?
        next unless invalid_scheme?(shemes_to_allow, attr_value)

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

  def invalid_scheme?(shemes_to_allow, url_like)
    url = ::Addressable::URI.parse(url_like) rescue nil
    return false if !url

    scheme = url.scheme
    return false if scheme.blank?

    scheme = scheme.downcase
    !shemes_to_allow.include?(scheme)
  end
end
