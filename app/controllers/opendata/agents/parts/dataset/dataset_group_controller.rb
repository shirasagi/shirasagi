class Opendata::Agents::Parts::Dataset::DatasetGroupController < ApplicationController
  include Cms::PartFilter::View
  helper Opendata::UrlHelper
  helper Cms::ListHelper

  private

  def category
    return nil unless @cur_node = cur_node
    return nil if @cur_node.route != "opendata/dataset_category"
    name = File.basename(File.dirname(@cur_path))
    Opendata::Node::Category.site(@cur_site).and_public.where(filename: /\/#{name}$/).first
  end

  public

  def index
    cond = {}
    cond[:category_ids] = @cate.id if @cate = category

    @items = Opendata::DatasetGroup.site(@cur_site).and_public.
      where(cond).
      order_by(@cur_part.sort_hash).
      limit(10)

    render
  end
end
