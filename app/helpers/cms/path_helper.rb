module Cms::PathHelper
  def cms_mobile_preview_path(params = {})
    if params[:path]
      params[:path] = ::File.join(@cur_site.mobile_location, params[:path])
      params[:path].sub!(/^\/+/, "")
    end
    cms_preview_path(params)
  end
end
