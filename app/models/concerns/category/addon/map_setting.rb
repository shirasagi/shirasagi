module Category::Addon
  module MapSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :map_icon_url, type: String
      permit_params :map_icon_url
    end
  end
end
