module Facility::Addon::Use
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_uses, class_name: "Facility::Node::Use"
      permit_params st_use_ids: []
    end

    set_order 510
  end
end
