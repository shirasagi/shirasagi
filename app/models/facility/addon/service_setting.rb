module Facility::Addon
  module ServiceSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_services, class_name: "Facility::Node::Service"
      permit_params st_service_ids: []
    end

    set_order 430
  end
end
