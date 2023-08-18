module Opendata::Addon::ListNodeSetting
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    # field :view_route, type: String
    field :limit, type: Integer, default: 10
    # permit_params :view_route
    permit_params :limit
  end
end
