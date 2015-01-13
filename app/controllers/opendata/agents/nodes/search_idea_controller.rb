class Opendata::Agents::Nodes::SearchIdeaController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  public
    def index
      case params[:sort]
      when "released"
        sort = { released: -1 }
      when "popular"
        sort = { point: -1 }
      when "attention"
        sort = { downloaded: -1 }
      else
        sort = { released: -1 }
      end

      @model = Opendata::Idea

      focus = params[:s] || {}
      focus = focus.merge(site: @cur_site)

      @items = @model.site(@cur_site).public.
        search(focus).
        order_by(sort).
        page(params[:page]).
        per(20)

      respond_to do |format|
        format.html { render }
        format.rss  { render_rss @cur_node, @items }
      end
    end
end
