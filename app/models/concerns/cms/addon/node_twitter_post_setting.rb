module Cms::Addon::NodeTwitterPostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :node_twitter_auto_post, type: String
    field :node_sns_auto_delete, type: String
    validates :node_twitter_auto_post, inclusion: { in: %w(expired active), allow_blank: true }
    validates :node_sns_auto_delete, inclusion: { in: %w(expired active), allow_blank: true }
    permit_params :node_sns_auto_delete, :node_twitter_auto_post
  end

  def node_twitter_auto_post_options
    %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_sns_auto_delete_options
    %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_twitter_auto_post_enabled?
    node_twitter_auto_post == 'active'
  end

  def node_sns_auto_delete_enabled?
    node_sns_auto_delete == 'active'
  end
end
