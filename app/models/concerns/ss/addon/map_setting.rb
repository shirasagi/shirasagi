module SS::Addon
  module MapSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_api, type: String
      field :map_api_key, type: String

      permit_params :map_api, :map_api_key
    end

    def map_api_options
      [
        [I18n.t("views.options.map_api.googlemaps"), "googlemaps"],
        [I18n.t("views.options.map_api.openlayers"), "openlayers"],
      ]
    end

    def map_setting
      {
        api: map_api,
        api_key: map_api_key,
      }
    end
  end
end
