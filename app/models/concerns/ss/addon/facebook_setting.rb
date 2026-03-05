module SS::Addon::FacebookSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :facebook_app_id, type: String
    field :facebook_api_version, type: String
    permit_params :facebook_app_id, :facebook_api_version
  end

  def effective_facebook_api_version
    facebook_api_version.presence || SS::DEFAULT_FACEBOOK_API_VERSION
  end
end
