class Opendata::Agents::Nodes::Dataset::SearchDatasetGroupController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  def index
    @items = Opendata::DatasetGroup.site(@cur_site).and_public.
      search(params[:s]).
      order_by(name: 1).
      page(params[:page]).
      per(@cur_node.limit || 20)

    render
  end
end
