class Urgency::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :allowed?
  before_action :set_items
  before_action :set_item, only: [:show, :update]

  helper_method :readable_layout?, :default_layout?, :selected_layout?

  model Cms::Layout

  append_view_path "app/views/cms/layouts"
  navi_view "urgency/main/navi"

  private
  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def allowed?
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_items
    begin
      @default_layout = @model.find(@cur_node.read_attribute(:urgency_default_layout_id).to_i)
    rescue
      redirect_to urgency_error_path(id: 1)
      return
    end

    @cur_node = @cur_node.becomes_with_route
    @index_page = @cur_node.find_index_page
    if @index_page.blank?
      redirect_to urgency_error_path(id: 2)
      return
    end

    @items = [ @default_layout ]
    @model.site(@cur_site).node(@cur_node).
      ne(id: @default_layout.id).order_by(name: 1).each do |item|
      @items << item
    end
  end

  def set_item
    super
    raise "404" unless readable_layout?
  end

  def readable_layout?(item=nil)
    item = @item unless item
    @items.find { |i| i.id == item.id } ? true : false
  end

  def default_layout?(item=nil)
    item = @item unless item
    item.id == @default_layout.id
  end

  def selected_layout?(item=nil)
    item = @item unless item
    item.id == @index_page.layout_id
  end

  public
  def index
  end

  def show
  end

  def update
    render_update @cur_node.switch_layout(@item), location: { action: :index }
  end

  def error
  end
end
