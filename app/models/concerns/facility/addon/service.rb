module Facility::Addon
  module Service
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :services, class_name: "Facility::Node::Service"
      permit_params service_ids: []
    end

    set_order 310
  end
end
