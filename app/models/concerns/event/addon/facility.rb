module Event::Addon
  module Facility
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :facilities, class_name: "Facility::Node::Page"
      permit_params facility_ids: []
    end
  end
end
