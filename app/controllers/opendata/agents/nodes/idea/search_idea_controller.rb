class Opendata::Agents::Nodes::Idea::SearchIdeaController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  private

  def pages
    @model = Opendata::Idea

    focus = params.permit(s: [@model.search_params])[:s].presence || {}
    focus = focus.merge(site: @cur_site)

    case params.permit(:sort)[:sort]
    when "released"
      sort = { released: -1 }
    when "popular"
      sort = { point: -1 }
    when "attention"
      sort = { commented: -1 }
    else
      sort = { released: -1 }
    end

    @model.site(@cur_site).and_public.
      search(focus).
      order_by(sort)
  end

  def st_categories
    @cur_node.parent_idea_node.st_categories.presence || @cur_node.parent_idea_node.default_st_categories
  end

  public

  def index
    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @items = pages.page(params[:page]).per(@cur_node.limit || 20)
  end

  def rss
    @items = pages.limit(100)
    render_rss @cur_node, @items
  end
end
