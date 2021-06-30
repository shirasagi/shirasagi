module SS::Addon::LineSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :line_channel_secret, type: String
    field :line_channel_access_token, type: String
    permit_params :line_channel_secret, :line_channel_access_token
  end

  def line_token_enabled?
    line_channel_secret.present? && line_channel_access_token.present?
  end
end
