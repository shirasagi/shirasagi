class Ads::Agents::Nodes::BannerController < ApplicationController
  include Cms::NodeFilter::View

  public
    def index
      render nothing: true
    end

    def count
      filename = @cur_path.sub(".count", "")

      @item = Ads::Banner.site(@cur_site).public.
        filename(filename).first

      raise "404" unless @item

      log = Ads::AccessLog.find_or_create_by(
        site_id: @item.site_id,
        node_id: @item.parent.id,
        link_url: @item.link_url,
        date: Date.today
      )
      log.inc count: 1

      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"

      render nothing: true
    end
end
