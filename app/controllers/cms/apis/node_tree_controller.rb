class Cms::Apis::NodeTreeController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeHelper

  model Cms::Node

  def index
    @type = params[:type].presence || 'cms_nodes'

    if params[:id] != '0'
      @item = @model.find(params[:id])
    end

    items = root_items
    items += tree_items if @item

    data = items.sort{ |a, b| a.filename <=> b.filename }.map do |item|
      {
        name: item.name,
        filename: item.filename,
        depth: item.depth,
        url: item_url(item),
        tree_url: cms_apis_node_tree_path(id: item.id, type: @type),
        is_current: (@item.present? && item.id == @item.id),
        is_parent: (@item.present? && @item.filename.start_with?("#{item.filename}\/"))
      }
    end

    render json: { items: data }.to_json
  end

  private

  def item_url(item)
    if @type == 'cms/page'
      node_pages_path(cid: item.id)
    elsif @type == 'cms/part'
      node_parts_path(cid: item.id)
    elsif @type == 'cms/layout'
      node_layouts_path(cid: item.id)
    else
      item.respond_to?(:view_route) ? contents_path(item) : cms_node_nodes_path(cid: item.id)
    end
  end

  def root_items
    @model.site(@cur_site).
      where(depth: 1).
      allow(:read, @cur_user, site: @cur_site)
  end

  def tree_items
    items = []

    @item.parents.each do |item|
      next unless item.allowed?(:read, @cur_user, site: @cur_site)
      items += item.children.allow(:read, @cur_user, site: @cur_site)
    end

    items + @item.children.allow(:read, @cur_user, site: @cur_site)
  end
end
