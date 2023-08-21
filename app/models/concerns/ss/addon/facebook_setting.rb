module SS::Addon::FacebookSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :facebook_app_id, type: String
    permit_params :facebook_app_id
  end
end
