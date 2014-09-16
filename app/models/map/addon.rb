# coding: utf-8
module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 500

    included do
      field :map_loc, type: SS::Extensions::Array
      field :map_zoom, type: Integer
      field :map_points, type: Map::Extensions::MapPoints, default: []

      permit_params :map_loc, :map_zoom, map_points: [ :name, :loc, :text ]
    end
  end

end
