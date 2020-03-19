class Opendata::Agents::Parts::Dataset::DatasetGroupController < ApplicationController
  include Cms::PartFilter::View
  helper Opendata::UrlHelper
  helper Cms::ListHelper

  private

  def category
    return nil unless @cur_node = cur_node
    return nil if @cur_node.route != "opendata/dataset_category"
    name = File.basename(File.dirname(@cur_path))
    Opendata::Node::Category.site(@cur_site).and_public.where(filename: /\/#{::Regexp.escape(name)}$/).first
  end

  public

  def index
    cond = {}
    cond[:category_ids] = @cate.id if @cate = category

    if @cur_part.sort == 'count -1'
      pipes = []
      pipes << { "$match" => Opendata::Dataset.site(@cur_site).and_public.where(cond).selector }
      pipes << { "$unwind" => "$dataset_group_ids" }
      pipes << { "$group" => { "_id" => "$dataset_group_ids", "count" => { "$sum" => 1 } } }
      pipes << { "$sort" => { 'count' => -1, '_id' => 1 } }
      pipes << { '$limit' => @cur_part.limit }
      @items = Opendata::Dataset.collection.aggregate(pipes).map do |data|
        item = Opendata::DatasetGroup.where(_id: data['_id']).first
        next if item.blank?
        next if item.state != 'public'
        item
      end
      @items.compact!
    else
      @items = Opendata::DatasetGroup.site(@cur_site).and_public.
        where(cond).
        order_by(@cur_part.sort_hash).
        limit(@cur_part.limit)
    end

    render
  end
end
