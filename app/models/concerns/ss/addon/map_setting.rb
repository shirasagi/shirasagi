module SS::Addon
  module MapSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_api, type: String
      field :map_api_key, type: String
      field :map_api_layer, type: String

      permit_params :map_api, :map_api_key, :map_api_layer
    end

    def map_api_options
      %w(googlemaps openlayers).collect do |k|
        [I18n.t("ss.options.map_api.#{k}"), k]
      end
    end

    def map_api_layer_options
      SS.config.map.layers.collect do |layer|
        [layer['name'], layer['name']]
      end
    end

    def map_setting
      {
        api: map_api,
        api_key: map_api_key,
        api_layer: map_api_layer
      }
    end
  end
end
