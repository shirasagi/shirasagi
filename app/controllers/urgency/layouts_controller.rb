class Urgency::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  before_action :allowed?
  before_action :set_default_layout
  before_action :set_index_page

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

  def set_default_layout
    begin
      @default_layout = @model.all.site(@cur_site).find(@cur_node.read_attribute(:urgency_default_layout_id).to_i)
    rescue
      redirect_to urgency_error_path(id: 1)
      return
    end
  end

  def set_index_page
    @index_page = @cur_node.find_index_page
    if @index_page.blank?
      redirect_to urgency_error_path(id: 2)
      return
    end
  end

  def set_items
    @items ||= @model.all.site(@cur_site)
  end

  def set_item
    super
    raise "404" unless readable_layout?
  end

  def readable_layout?(item = nil)
    item = @item unless item
    @items.find { |i| i.id == item.id } ? true : false
  end

  def default_layout?(item = nil)
    item = @item unless item
    item.id == @default_layout.id
  end

  def selected_layout?(item = nil)
    item = @item unless item
    item.id == @index_page.layout_id
  end

  public

  def index
    set_items
    @items = @items.node(@cur_node)
    @items = @items.order_by(name: 1)
  end

  def show
  end

  def update
    render_update @cur_node.switch_layout(@item), location: { action: :index }
  end

  def error
  end
end
