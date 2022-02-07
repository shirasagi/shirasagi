module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :center_setting, type: String, default: "auto"
      field :set_center_position, type: String
      field :zoom_setting, type: String, default: "auto"
      field :set_zoom_level, type: Integer
      permit_params map_points: [ :name, :loc, :text, :link, :image ]
      permit_params :map_zoom_level, :center_setting, :set_center_position, :zoom_setting, :set_zoom_level

      after_save :save_geolocation, if: ->{ map_points.present? }
      after_destroy :remove_geolocation

      if respond_to? :liquidize
        liquidize do
          export :map_points
          export :map_zoom_level
        end
      end
    end

    def map_options
      options = {}
      if center_setting == "designated_location" && set_center_position.present?
        options[:center] = set_center_position.split(",").map(&:to_f)
      end
      if zoom_setting == "designated_level" && set_zoom_level.present?
        options[:zoom] = set_zoom_level
      end
      options
    end

    def save_geolocation
      if public?
        Map::Geolocation.update_with(self)
      else
        Map::Geolocation.remove_with(self)
      end
    end

    def remove_geolocation
      Map::Geolocation.remove_with(self)
    end
  end
end
