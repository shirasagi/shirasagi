class Rdf::Extensions::LangHash
  include Rdf::Extensions::HashLike

  LANG_JA = "ja".freeze
  LANG_EN = "en".freeze
  LANG_INVARIANT = "invariant".freeze
  LANGS = [LANG_JA, LANG_EN, LANG_INVARIANT].freeze

  def initialize(document)
    @document = document
  end

  def preferred_value(preferred_langs = LANGS)
    return nil if @document.blank?
    preferred_langs.each do |lang|
      lang = lang.to_s
      value = @document[lang]
      return value if value.present?
    end
    nil
  end
end
