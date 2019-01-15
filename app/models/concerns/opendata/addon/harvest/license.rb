module Opendata::Addon::Harvest::License
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :uid, type: String, default: nil
    permit_params :uid
  end
end
