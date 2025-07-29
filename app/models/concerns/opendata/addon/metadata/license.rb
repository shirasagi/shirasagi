module Opendata::Addon::Metadata::License
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :metadata_uid, type: SS::Extensions::Lines
    permit_params :metadata_uid
  end
end
