module Cms::Addon
  module Line::Service::GdChat
    extend ActiveSupport::Concern
    extend SS::Addon

    def api_url
      @api_url ||= SS.config.pippi.dig("gd_chat", "webhook_url")
    end
  end
end
