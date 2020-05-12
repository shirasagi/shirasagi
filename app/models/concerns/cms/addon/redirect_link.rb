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
  end
end
