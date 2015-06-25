module Map::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: Map::Extensions::Points, default: []

      permit_params map_points: [ :name, :loc, :text, :link, :image ]
    end
  end
end
