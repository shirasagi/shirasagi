module SS::Addon::TwitterSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :twitter_card, type: String
    field :twitter_username, type: String
    validates :twitter_card, inclusion: { in: %w(none summary summary_large_image), allow_blank: true }
    permit_params :twitter_card, :twitter_username
  end

  def twitter_card_options
    %w(none summary summary_large_image).map do |v|
      [I18n.t("views.options.twitter_card.#{v}"), v]
    end
  end

  def twitter_card_enabled?
    twitter_card.present? && twitter_card != 'none'
  end
end
