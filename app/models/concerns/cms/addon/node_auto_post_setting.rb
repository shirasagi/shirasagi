module Cms::Addon::NodeAutoPostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :node_facebook_auto_post, type: String
    field :node_twitter_auto_post, type: String
    field :node_sns_auto_delete, type: String
    field :node_edit_auto_post, type: String
    validates :node_facebook_auto_post, inclusion: { in: %w(none expired active), allow_blank: true }
    validates :node_twitter_auto_post, inclusion: { in: %w(none expired active), allow_blank: true }
    validates :node_sns_auto_delete, inclusion: { in: %w(none expired active), allow_blank: true }
    validates :node_edit_auto_post, inclusion: { in: %w(none expired active), allow_blank: true }
    permit_params :node_facebook_auto_post, :node_twitter_auto_post
    permit_params :node_sns_auto_delete, :node_edit_auto_post
  end

  def node_facebook_auto_post_options
    %w(none expired active).map do |v|
      [I18n.t("views.options.node_auto_post_setting.#{v}"), v]
    end
  end

  def node_twitter_auto_post_options
    %w(none expired active).map do |v|
      [I18n.t("views.options.node_auto_post_setting.#{v}"), v]
    end
  end

  def node_sns_auto_delete_options
    %w(none expired active).map do |v|
      [I18n.t("views.options.node_auto_post_setting.#{v}"), v]
    end
  end

  def node_edit_auto_post_options
    %w(none expired active).map do |v|
      [I18n.t("views.options.node_auto_post_setting.#{v}"), v]
    end
  end

  def node_facebook_auto_post_enabled?
    node_facebook_auto_post.present? && node_facebook_auto_post == 'active'
  end

  def node_twitter_auto_post_enabled?
    node_twitter_auto_post.present? && node_twitter_auto_post == 'active'
  end

  def node_sns_auto_delete_enabled?
    node_sns_auto_delete.present? && node_sns_auto_delete == 'active'
  end

  def node_edit_auto_post_enabled?
    node_edit_auto_post.present? && node_edit_auto_post == 'active'
  end
end
