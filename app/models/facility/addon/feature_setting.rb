module Facility::Addon
  module FeatureSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_features, class_name: "Facility::Node::Feature"
      permit_params st_feature_ids: []
    end

    set_order 510
  end
end
