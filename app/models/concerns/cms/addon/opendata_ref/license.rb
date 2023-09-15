module Cms::Addon::OpendataRef::License
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_licenses, class_name: "Opendata::License", metadata: { on_copy: :clear }
    permit_params opendata_license_ids: []
  end
end
