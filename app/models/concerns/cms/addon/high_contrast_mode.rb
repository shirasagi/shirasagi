module Cms::Addon
  module HighContrastMode
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :high_contrast_mode, type: String, default: "disabled"
      field :font_color, type: String
      field :background_color, type: String
      permit_params :high_contrast_mode, :font_color, :background_color

      validates :font_color, presence: true, if: -> { high_contrast_mode_enabled? }
      validates :background_color, presence: true, if: -> { high_contrast_mode_enabled? }
    end

    def high_contrast_mode_enabled?
      high_contrast_mode == "enabled"
    end

    def high_contrast_mode_options
      [
        [I18n.t("views.options.state.disabled"), "disabled"],
        [I18n.t("views.options.state.enabled"), "enabled"],
      ]
    end
  end
end
