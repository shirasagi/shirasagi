class Jmaxml::FiltersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Filter

  before_action :node_becomes_with_route

  navi_view "rss/main/navi"

  private
  def fix_params
    {}
  end

  def node_becomes_with_route
    @cur_node = @cur_node.becomes_with_route if !@cur_node.is_a?(Rss::Node::WeatherXml)
    @cur_node
  end

  def set_items
    node_becomes_with_route
    @items = @cur_node.filters.order_by(updated: -1)
  end

  def set_item
    set_items
    @item = @items.find params[:id]
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.kind_of?(String)
    set_items
    @items = @items.in(id: ids)
    raise "400" unless @items.present?
  end

  public
  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    set_items
    @items = @items.search(params[:s]).page(params[:page]).per(50)
  end

  def show
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    @item = @cur_node.filters.new pre_params.merge(fix_params)
  end

  def create
    @item = @cur_node.filters.new get_params
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end
end
