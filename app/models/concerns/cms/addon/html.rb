module Cms::Addon
  module Html
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      permit_params :html

      validate :validate_script_tag
    end

    def validate_script_tag
      if html.present?
        errors.add(:html, "はscriptタグを含めることはできません。") if html.include?("<script")
      end
    end
  end
end
