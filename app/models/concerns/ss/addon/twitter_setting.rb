module SS::Addon::TwitterSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :twitter_poster_state, type: String, default: "enabled"
    field :twitter_card, type: String
    field :twitter_username, type: String
    field :twitter_default_image_url, type: String
    field :twitter_consumer_key, type: String
    field :twitter_consumer_secret, type: String
    field :twitter_access_token, type: String
    field :twitter_access_token_secret, type: String
    validates :twitter_card, inclusion: { in: %w(none summary summary_large_image), allow_blank: true }
    permit_params :twitter_poster_state
    permit_params :twitter_card, :twitter_username, :twitter_default_image_url
    permit_params :twitter_consumer_key, :twitter_consumer_secret
    permit_params :twitter_access_token, :twitter_access_token_secret
  end

  def twitter_poster_state_options
    %w(enabled disabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  def twitter_card_options
    %w(none summary summary_large_image).map do |v|
      [I18n.t("ss.options.twitter_card.#{v}"), v]
    end
  end

  def twitter_poster_enabled?
    (twitter_poster_state == "enabled") && twitter_token_enabled?
  end

  def twitter_card_enabled?
    twitter_card.present? && twitter_card != 'none'
  end

  def twitter_token_enabled?
    twitter_consumer_key.present? && twitter_consumer_secret.present? &&
      twitter_access_token.present? && twitter_access_token_secret.present?
  end
end
