module Cms::Addon
  module RedirectLink
    extend ActiveSupport::Concern
    extend SS::Addon

    def url
      ret = redirect_link rescue nil
      ret.presence || super
    end

    def full_url
      ret = redirect_link rescue nil
      ret.presence || super
    end
  end
end
