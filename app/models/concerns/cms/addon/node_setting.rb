module Cms::Addon
  module NodeSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :view_route, type: String
      permit_params :view_route
    end
  end
end
