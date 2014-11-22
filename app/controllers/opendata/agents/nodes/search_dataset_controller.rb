class Opendata::Agents::Nodes::SearchDatasetController < ApplicationController
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

      @model = Opendata::Dataset

      @items = @model.site(@cur_site).public.
        search(params[:s].merge(site: @cur_site)).
        order_by(sort).
        page(params[:page]).
        per(20)

      respond_to do |format|
        format.html { render }
        format.rss  { render_rss @cur_node, @items }
      end
    end
end
