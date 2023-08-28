module Cms::Addon::Site
  module NodeSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :rss_recent_state, type: String, default: "disabled"
      permit_params :rss_recent_state
    end

    def rss_recent_state_options
      %w(disabled enabled).map do |v|
        [ I18n.t("ss.options.state.#{v}"), v ]
      end
    end

    def rss_recent_enabled?
      rss_recent_state == "enabled"
    end

    def rss_recent_disabled?
      !rss_recent_enabled?
    end
  end
end
