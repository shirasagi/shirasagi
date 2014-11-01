module Ads::Agents::Nodes::Banner
  class ViewController < ApplicationController
    include Cms::NodeFilter::View

    public
      def count
        filename = @cur_path.sub(".count", "")

        @item = Ads::Banner.site(@cur_site).public.
          filename(filename).first

        raise "404" unless @item

        log = Ads::AccessLog.find_or_create_by({
          site_id: @item.site_id,
          node_id: @item.parent.id,
          link_url: @item.link_url,
          date: Date.today
        })
        log.inc count: 1

        render nothing: true
      end
  end
end
