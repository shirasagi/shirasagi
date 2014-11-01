module Ads::Agents::Parts::Banner
  class ViewController < ApplicationController
    include Cms::PartFilter::View

    public
      def index
        @items = Ads::Banner.site(@cur_site).public(@cur_date).
          order_by(order: 1)
      end
  end
end
