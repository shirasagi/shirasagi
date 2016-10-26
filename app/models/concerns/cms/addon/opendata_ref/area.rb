module Cms::Addon::OpendataRef::Area
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_areas, class_name: "Opendata::Node::Area", metadata: { on_copy: :clear }
    permit_params opendata_area_ids: []
  end
end
