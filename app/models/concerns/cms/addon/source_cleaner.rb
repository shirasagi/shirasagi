module Cms::Addon
  module SourceCleaner
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :target_type, type: String
      field :target_value, type: String
      field :action_type, type: String
      field :replaced_value, type: String

      validates :target_type, presence: true
      validates :target_value, presence: true
      validates :action_type, presence: true

      validate :validate_action_type
      validate :validate_target_type

      permit_params :target_type, :target_value, :action_type, :replaced_value
    end

    def validate_action_type
      self.replaced_value = nil if action_type != "replace"
    end

    def validate_target_type
      if action_type == "replace" && replaced_value.blank?
        errors.add :replaced_value, :blank
      end
    end

    def target_type_options
      [
        [I18n.t("cms.options.target_type.tag"), "tag"],
        [I18n.t("cms.options.target_type.attribute"), "attribute"],
        [I18n.t("cms.options.target_type.string"), "string"],
        [I18n.t("cms.options.target_type.regexp"), "regexp"],
      ]
    end

    def action_type_options
      [
        [I18n.t("cms.options.action_type.remove"), "remove"],
        [I18n.t("cms.options.action_type.replace"), "replace"],
      ]
    end
  end
end
