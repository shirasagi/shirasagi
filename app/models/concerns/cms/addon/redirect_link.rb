module Cms::Addon
  module RedirectLink
    extend ActiveSupport::Concern
    extend SS::Addon

    def url
      effective_redirect_link.presence || super
    end

    def full_url
      effective_redirect_link.presence || super
    end
  end
end
