module Facility::Addon
  module FocusSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :center_point, type: ::Map::Extensions::Point

      permit_params center_point: [ :loc, :zoom_level ]
    end
  end
end
