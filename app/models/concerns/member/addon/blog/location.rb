module Member::Addon::Blog
  module Location
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :blog_page_locations, class_name: "Member::Node::BlogPageLocation"
      permit_params blog_page_location_ids: []
    end
  end
end
