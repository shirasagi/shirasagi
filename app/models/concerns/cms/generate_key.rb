module Cms::GenerateKey
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :generate_key, type: String
    before_save :set_generate_key
  end

  private

  def set_generate_key
    return if generate_keys.blank?
    return if !serve_static_file?
    self.generate_key ||= generate_keys[id % generate_keys.size]
  end

  public

  def generate_keys
    @_generate_keys ||= begin
      SS.config.cms.generate_key || []
    end
  end
end
