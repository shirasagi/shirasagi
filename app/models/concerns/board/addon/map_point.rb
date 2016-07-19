module Board::Addon
  module MapPoint
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :point, type: Map::Extensions::Point
      permit_params point: [ :zoom_level, { loc: [ :lat, :lng ] } ]
    end
  end
end
