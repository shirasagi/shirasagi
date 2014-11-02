class Ads::Agents::Parts::BannerController < ApplicationController
  include Cms::PartFilter::View

  public
    def index
      sort = @cur_part.sort_hash

      @items = Ads::Banner.site(@cur_site).public(@cur_date).
        order_by(sort)

      @items = @items.shuffle if sort[:random]
    end
end
