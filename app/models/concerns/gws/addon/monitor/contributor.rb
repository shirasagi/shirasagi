module Gws::Addon::Monitor::Contributor
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :contributor_model, type: String
    field :contributor_id, type: String
    field :contributor_name, type: String
    permit_params :contributor_model, :contributor_id, :contributor_name
  end
end

