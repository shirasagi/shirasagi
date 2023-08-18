module Member::Addon::Photo
  module Location
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :photo_locations, class_name: "Member::Node::PhotoLocation"
      permit_params photo_location_ids: []
    end
  end
end
