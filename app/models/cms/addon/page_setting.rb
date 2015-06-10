module Cms::Addon
  module PageSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :auto_description, type: String, default: "enabled"
      field :auto_keywords, type: String, default: "enabled"
      field :keywords, type: SS::Extensions::Words

      permit_params :auto_keywords, :auto_description
      permit_params :keywords
    end

    public
      def auto_keywords_options
        [
          [I18n.t("views.options.state.enabled"), "enabled"],
          [I18n.t("views.options.state.disabled"), "disabled"],
        ]
      end

      def auto_description_options
        [
          [I18n.t("views.options.state.enabled"), "enabled"],
          [I18n.t("views.options.state.disabled"), "disabled"],
        ]
      end

      def auto_keywords_enabled?
        auto_keywords == "enabled"
      end

      def auto_description_enabled?
        auto_description == "enabled"
      end
  end
end
