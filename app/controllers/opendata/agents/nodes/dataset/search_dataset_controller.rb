class Opendata::Agents::Nodes::Dataset::SearchDatasetController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  private
    def pages
      @model = Opendata::Dataset

      focus = params[:s] || {}
      focus = focus.merge(site: @cur_site)

      sort = Opendata::Dataset.sort_hash params[:sort]

      @model.site(@cur_site).public.
        search(focus).
        order_by(sort)
    end

  public
    def index
      @items = pages.page(params[:page]).per(20)
    end

    def rss
      @items = pages.limit(100)
      render_rss @cur_node, @items
    end
end
