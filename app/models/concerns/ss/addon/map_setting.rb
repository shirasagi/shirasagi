module SS::Addon
  module MapSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_api, type: String
      field :map_api_key, type: String
      field :map_api_layer, type: String
      field :show_google_maps_search, type: String, default: "active"
      field :map_api_mypage, type: String, default: "active"
      field :map_center, type: Map::Extensions::Loc
      field :map_max_number_of_markers, type: Integer

      permit_params :map_api, :map_api_key, :map_api_layer, :show_google_maps_search, :map_api_mypage
      permit_params :map_max_number_of_markers, map_center: %i[lat lng]

      validates :map_max_number_of_markers, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
      validate :validate_map_max_number_of_markers
    end

    def map_api_options
      %w(googlemaps openlayers).collect do |k|
        [I18n.t("ss.options.map_api.#{k}"), k]
      end
    end

    def show_google_maps_search_options
      %w(active expired).collect do |k|
        [I18n.t("ss.options.state.#{k}"), k]
      end
    end

    def show_google_maps_search_enabled?
      show_google_maps_search == "active"
    end

    def map_api_layer_options
      map_layers.keys.map { |k| [k, k] }
    end

    def map_layers
      @_map_layers ||= SS.config.map.layers.index_by { |layer| layer["name"] }
    end

    def map_effective_layers
      layer = map_layers[map_api_layer] || map_layers[map_layers.keys.first]
      [layer]
    end

    def map_api_mypage_options
      %w(active expired).collect do |k|
        [I18n.t("ss.options.state.#{k}"), k]
      end
    end

    def map_setting
      {
        api: map_api,
        api_key: map_api_key,
        api_layer: map_api_layer
      }
    end

    private

    def validate_map_max_number_of_markers
      return if !map_max_number_of_markers.numeric?
      return if map_max_number_of_markers <= Map.system_limit_number_of_markers

      errors.add :map_max_number_of_markers, :less_than_or_equal_to, count: Map.system_limit_number_of_markers
    end
  end
end
