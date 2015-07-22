module Cms::PathHelper
  public
    def cms_mobile_preview_path(params = {})
      if params[:path]
        params[:path] = ::File.join(SS.config.mobile.location, params[:path])
        params[:path].sub!(/^\/+/, "")
      end
      cms_preview_path(params)
    end
end
