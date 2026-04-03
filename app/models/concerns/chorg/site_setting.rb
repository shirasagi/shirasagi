module Chorg::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    embeds_ids :chorg_sites, class_name: "Cms::Site"
    permit_params chorg_site_ids: []
  end
end
