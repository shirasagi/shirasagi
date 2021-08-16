module Cms::Addon::NodeTwitterPostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :node_twitter_auto_post, type: String
    field :node_twitter_post_format, type: String
    permit_params :node_twitter_auto_post, :node_twitter_post_format
  end

  def node_twitter_auto_post_options
    %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_twitter_post_format_options
    I18n.t("cms.options.twitter_post_format").map { |k, v| [v, k] }
  end

  def node_twitter_auto_post_enabled?
    node_twitter_auto_post == 'active'
  end
end
