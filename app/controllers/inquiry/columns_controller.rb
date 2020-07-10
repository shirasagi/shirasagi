class Inquiry::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Inquiry::Column

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  before_action :check_permission

  private

  def fix_params
    { cur_site: @cur_site, node_id: @cur_node.id }
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(node_id: @cur_node.id).
      order_by(order: 1).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    entries = @selected_items
    @items = []

    entries.each do |item|
      item = item.becomes_with_route rescue item
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
