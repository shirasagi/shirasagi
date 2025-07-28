module Urgency::Addon::SiteSetting
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :related_urgency_sites, class_name: "Cms::Site"
    permit_params related_urgency_site_ids: []
  end

  def related_urgency_nodes
    self.class.in(site_id: related_urgency_site_ids).
      where(:id.ne => id).
      where(filename: filename)
  end
end
