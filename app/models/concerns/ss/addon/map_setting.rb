module SS::Addon
  module MapSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_api_key, type: String
      permit_params :map_api_key
    end

    def map_setting
      { api_key: map_api_key }
    end
  end
end
