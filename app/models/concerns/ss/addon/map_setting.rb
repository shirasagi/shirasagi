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
      map_layers.keys.map { |k| [k, k] }
    end

    def map_layers
      @_map_layers ||= SS.config.map.layers.map { |layer| [layer["name"], layer] }.to_h
    end

    def map_effective_layers
      layer = map_layers[map_api_layer] || map_layers[map_layers.keys.first]
      [layer]
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
