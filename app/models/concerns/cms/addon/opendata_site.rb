module Cms::Addon::OpendataSite
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_sites, class_name: "Cms::Site", metadata: { on_copy: :clear }
    permit_params opendata_site_ids: []
  end
end
