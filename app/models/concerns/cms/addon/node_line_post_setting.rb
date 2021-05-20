module Cms::Addon::NodeLinePostSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :node_line_auto_post, type: String
    field :node_line_post_format, type: String
    permit_params :node_line_auto_post, :node_line_post_format
  end

  def node_line_auto_post_options
    %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def node_line_post_format_options
    I18n.t("cms.options.line_post_format").map { |k, v| [v, k] }
  end
end
