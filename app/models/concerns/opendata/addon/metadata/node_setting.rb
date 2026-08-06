module Opendata::Addon::Metadata::NodeSetting
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :metadata_japanese_local_goverment_code, type: String
    field :metadata_local_goverment_name, type: String

    permit_params :metadata_japanese_local_goverment_code, :metadata_local_goverment_name
  end
end
