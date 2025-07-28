module Cms::SyntaxChecker::UrlSchemeSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :syntax_checker_url_scheme_attributes, type: SS::Extensions::Words
    field :syntax_checker_url_scheme_schemes, type: SS::Extensions::Words

    before_validation :normalize_syntax_checker_url_scheme_schemes
  end

  private

  def normalize_syntax_checker_url_scheme_schemes
    return unless syntax_checker_url_scheme_schemes_changed?

    schemes = self.syntax_checker_url_scheme_schemes.select(&:present?)
    schemes = schemes.map do |scheme|
      scheme = scheme.strip
      scheme = scheme[0..-2] if scheme.end_with?(":")
      scheme
    end

    self.syntax_checker_url_scheme_schemes = schemes
  end
end
