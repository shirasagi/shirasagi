module Facility::Addon
  module Feature
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :features, class_name: "Facility::Node::Feature"
      permit_params feature_ids: []
    end

    set_order 310
  end
end
