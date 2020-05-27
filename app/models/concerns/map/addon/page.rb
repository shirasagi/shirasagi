module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :center_setting, type: String
      field :set_center_position, type: String
      field :zoom_setting, type: String
      field :set_zoom_level, type: Integer
      permit_params map_points: [ :name, :loc, :text, :link, :image ]
      permit_params :map_zoom_level, :center_setting, :set_center_position, :zoom_setting, :set_zoom_level

      if respond_to? :liquidize
        liquidize do
          export :map_points
          export :map_zoom_level
        end
      end
    end
  end
end
