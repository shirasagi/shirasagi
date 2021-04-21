module SS::Addon::PartnerSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :partner_sites, class_name: "SS::Site"
    permit_params partner_site_ids: []
  end
end
