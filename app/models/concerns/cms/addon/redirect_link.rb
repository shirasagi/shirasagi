module Cms::Addon
  module RedirectLink
    extend ActiveSupport::Concern
    extend SS::Addon

    def url
      redirect_link.presence || super
    end

    def full_url
      redirect_link.presence || super
    end

    module ClassMethods
      def redirect_link_enabled?
        SS.config.cms.dig("disable_redirect_link") == false
      end
    end
  end
end
