module Rdf::LangHash
  LANG_JA = "ja".freeze
  LANG_EN = "en".freeze
  LANG_INVARIANT = "invariant".freeze
  LANGS = [LANG_JA, LANG_EN, LANG_INVARIANT].freeze

  private
    def lang_hash_value(hash)
      return nil if hash.blank?
      LANGS.each do |lang|
        return hash[lang] if hash[lang].present?
      end
      hash.map{ |_, v| v }.select { |v| v.present? }.first
    end

    def normalize_lang_hash(hash)
      return nil if hash.blank?
      hash = hash.reject { |k, v| v.blank? }
      return nil if hash.blank?
      hash
    end
end