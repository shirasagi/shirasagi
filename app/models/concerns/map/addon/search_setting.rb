module Map::Addon
  module SearchSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_center_setting, type: String, default: "auto"
      field :map_center, type: Map::Extensions::Loc
      field :map_zoom_setting, type: String, default: "auto"
      field :map_zoom_level, type: Integer
      field :map_cluster_setting, type: String, default: "enabled"

      permit_params :map_center_setting
      permit_params :map_center
      permit_params :map_zoom_setting
      permit_params :map_zoom_level
      permit_params :map_cluster_setting

      validates :map_zoom_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 21, allow_blank: true }
      validates :map_center, presence: true, if: ->{ map_center_setting == "fixed" }
      validates :map_zoom_level, presence: true, if: ->{ map_zoom_setting == "fixed" }
    end

    def map_center_setting_options
      I18n.t("map.options.center_setting").map { |k, v| [v, k] }
    end

    def map_zoom_setting_options
      I18n.t("map.options.zoom_setting").map { |k, v| [v, k] }
    end

    def map_cluster_setting_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"]
      ]
    end

    def map_cluster_enabled?
      map_cluster_setting == "enabled"
    end

    def map_options
      opts = {}
      opts[:center] = map_center if map_center_setting == "fixed" && map_center.present?
      opts[:zoom] = map_zoom_level if map_zoom_setting == "fixed" && map_zoom_level.present?
      opts
    end
  end
end
