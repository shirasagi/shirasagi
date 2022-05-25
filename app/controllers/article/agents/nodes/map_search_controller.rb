class Article::Agents::Nodes::MapSearchController < ApplicationController
  include Cms::NodeFilter::View

  append_view_path "app/views/facility/agents/addons/search_setting/view"
  append_view_path "app/views/facility/agents/addons/search_result/view"

  before_action :set_query, only: [:index, :map, :result]

  private

  def set_query
    @keyword = params[:keyword].try { |keyword| keyword.to_s }
    @columns = params[:columns].permit! rescue []
    @columns = @columns.to_h.map { |k, v| v }
    @categories = (params[:categories] || []).reject(&:blank?)
  end

  def pages
    Article::Page.public_list(site: @cur_site, node: @cur_node, date: @cur_date)
  end

  def set_items
    @items = pages.
      search(name: @keyword).
      order_by(@cur_node.sort_hash)

    @items = @items.select { |item| search_columns(item) }
  end

  def search_columns(item)
    @columns_hash = @columns.map.with_index do |values, idx|
      col = @cur_node.map_search_options[idx]
      [col['name'], values.reject(&:empty?)]
    end.to_h

    @columns_hash.each do |name, values|
      next if values.blank?
      col_val = item.column_values.to_a.find { |cv| cv['name'] == name }
      return false unless col_val
      return false if values.present? && !col_val.search_values(values)
    end
    true
  end

  def set_markers
    @markers = []

    @items.each do |item|
      category_ids, image_ids = item.categories.pluck(:id, :image_id).transpose
      image_id = image_ids.try(:first)
      image_url = SS::File.where(id: image_id).first.try(:url) if image_id.present?

      item.map_points.each do |point|
        point[:id] = item.id
        point[:html] = view_context.render_marker_info(item, point)
        point[:category] = category_ids
        point[:image] = image_url if image_url.present?
        @markers.push point
      end
    end
  end

  def set_filter_items
    category_ids = @items.map(&:category_ids).flatten.uniq
    @filter_categories_array = @cur_node.st_categories.select { |c| category_ids.include?(c.id) }
  end

  public

  def index
    render 'index', locals: { search_path: "#{@cur_node.url}map.html" }
  end

  def map
    set_items
    set_markers
    set_filter_items
    @current = "map"
    render 'map'
  end
end
