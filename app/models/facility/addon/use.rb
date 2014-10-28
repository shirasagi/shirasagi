module Facility::Addon
  module Use
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :uses, class_name: "Facility::Node::Use"
      permit_params use_ids: []
    end

    set_order 310
  end
end
