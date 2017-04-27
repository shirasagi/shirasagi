module SS::Addon::SiteAutoPostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :site_facebook_auto_post, type: String, default: "expired"
    field :site_twitter_auto_post, type: String, default: "expired"
    field :site_sns_auto_delete, type: String, default: "expired"
    field :site_edit_auto_post, type: String, default: "expired"
    validates :site_facebook_auto_post, inclusion: { in: %w(expired active), allow_blank: true }
    validates :site_twitter_auto_post, inclusion: { in: %w(expired active), allow_blank: true }
    validates :site_sns_auto_delete, inclusion: { in: %w(expired active), allow_blank: true }
    validates :site_edit_auto_post, inclusion: { in: %w(expired active), allow_blank: true }
    permit_params :site_facebook_auto_post, :site_twitter_auto_post
    permit_params :site_sns_auto_delete, :site_edit_auto_post
  end

  def site_facebook_auto_post_options
    %w(expired active).map do |v|
      [I18n.t("views.options.state.#{v}"), v]
    end
  end

  def site_twitter_auto_post_options
    %w(expired active).map do |v|
      [I18n.t("views.options.state.#{v}"), v]
    end
  end

  def site_sns_auto_delete_options
    %w(expired active).map do |v|
      [I18n.t("views.options.state.#{v}"), v]
    end
  end

  def site_edit_auto_post_options
    %w(expired active).map do |v|
      [I18n.t("views.options.state.#{v}"), v]
    end
  end

  def site_facebook_auto_post_enabled?
    site_facebook_auto_post == 'active'
  end

  def site_twitter_auto_post_enabled?
    site_twitter_auto_post == 'active'
  end

  def site_sns_auto_delete_enabled?
    site_sns_auto_delete == 'active'
  end

  def site_edit_auto_post_enabled?
    site_edit_auto_post == 'active'
  end
end
