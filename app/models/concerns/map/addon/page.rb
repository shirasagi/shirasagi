module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      permit_params map_points: [ :name, :loc, :text, :link, :image ]
      permit_params :map_zoom_level
    end
  end
end
