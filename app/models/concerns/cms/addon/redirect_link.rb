module Cms::Addon
  module RedirectLink
    extend ActiveSupport::Concern
    extend SS::Addon

    def url
      s = @cur_site || site
      return super unless s.try(:redirect_link_enabled?)

      ret = try(:redirect_link).presence
      return super unless ret
      return super unless UrlValidator.valid?(ret)

      ret
    end

    def full_url
      s = @cur_site || site
      return super unless s.try(:redirect_link_enabled?)

      ret = try(:redirect_link).presence
      return super unless ret
      return super unless UrlValidator.valid?(ret)

      ret
    end
  end
end
