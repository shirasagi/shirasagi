module Cms::Addon::NodeTwitterPostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :node_twitter_poster_state, type: String
    field :node_twitter_auto_post, type: String
    field :node_twitter_edit_auto_post, type: String
    permit_params :node_twitter_poster_state, :node_twitter_auto_post, :node_twitter_edit_auto_post
  end

  def node_twitter_poster_state_options
    %w(active expired).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_twitter_auto_post_options
    %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_twitter_edit_auto_post_options
    %w(disabled enabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_twitter_poster_enabled?
    node_twitter_poster_state != 'expired'
  end

  def node_twitter_auto_post_enabled?
    node_twitter_auto_post == 'active'
  end

  def node_twitter_edit_auto_post_enabled?
    node_twitter_edit_auto_post == 'enabled'
  end
end
