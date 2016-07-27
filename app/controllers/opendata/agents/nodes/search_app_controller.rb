class Opendata::Agents::Nodes::SearchAppController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  private
    def pages
      @model = Opendata::App::App

      focus = params[:s] || {}
      focus = focus.merge(site: @cur_site)

      case params[:sort]
      when "released"
        sort = { released: -1 }
      when "popular"
        sort = { point: -1 }
      when "attention"
        sort = { executed: -1 }
      else
        sort = { released: -1 }
      end

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
