module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 320

    included do
      field :map_loc, type: SS::Extensions::Array, default: []
      field :map_zoom, type: Integer
      field :map_points, type: Map::Extensions::MapPoints, default: []

      permit_params :map_loc, :map_zoom, map_points: [ :name, :loc, :text, :link, :pointer_image ]
    end
  end

end
