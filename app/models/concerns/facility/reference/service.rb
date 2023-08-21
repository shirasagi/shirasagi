module Facility::Reference
  module Service
    extend ActiveSupport::Concern

    included do
      embeds_ids :services, class_name: "Facility::Node::Service"
      embeds_ids :st_services, class_name: "Facility::Node::Service"
      permit_params service_ids: [], st_service_ids: []
    end
  end
end
