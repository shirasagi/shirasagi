class Opendata::Agents::Nodes::Dataset::SearchDatasetController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  private

  def pages
    @model = Opendata::Dataset

    focus = params.permit(s: [@model.search_params])[:s].presence || {}
    focus = focus.merge(site: @cur_site)

    sort = Opendata::Dataset.sort_hash(params.dig(:s, :sort) || params.permit(:sort)[:sort])

    @model.site(@cur_site).and_public.
      search(focus).
      order_by(sort)
  end

  def st_categories
    @cur_node.parent_dataset_node.st_categories.presence || @cur_node.parent_dataset_node.default_st_categories
  end

  public

  def index
    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
    @items = pages.page(params[:page]).per(@cur_node.limit || 20)
  end

  def index_tags
    @cur_node.layout = nil
    @tags = pages.aggregate_array :tags
    render "opendata/agents/nodes/dataset/search_dataset/tags", layout: "opendata/dataset_aggregation"
  end

  def search
    @model = Opendata::Dataset
    @cur_categories = st_categories.map { |cate| cate.children.and_public.sort(order: 1).to_a }.flatten
  end

  def rss
    @items = pages.limit(100)
    render_rss @cur_node, @items
  end
end
