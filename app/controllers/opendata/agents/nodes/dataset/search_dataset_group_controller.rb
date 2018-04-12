class Opendata::Agents::Nodes::Dataset::SearchDatasetGroupController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  def index
    @items = Opendata::DatasetGroup.site(@cur_site).and_public.
      search(params[:s]).
      order_by(sort_hash).
      page(params[:page]).
      per(@cur_node.limit || 20)

    render
  end

  private

  def sort_hash
    sort = params.dig(:s, :sort) || params.permit(:sort)[:sort]
    return { name: 1 } if sort.blank?
    { sort.sub(/ .*/, "") => (sort.end_with?('-1') ? -1 : 1) }
  end
end
