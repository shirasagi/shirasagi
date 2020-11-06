module Urgency::Addon::SiteSetting
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :related_urgency_sites, class_name: "Cms::Site"
    permit_params related_urgency_site_ids: []
  end
end
