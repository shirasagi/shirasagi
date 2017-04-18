module Sns::PublicNoticeFilter
  extend ActiveSupport::Concern

  included do
    model Sys::Notice
  end

  def index
    set_items
    @items = @items.
      search(params[:s]).
      order_by(updated: -1, id: -1).
      page(params[:page]).per(50)
  end

  def show
    set_items
    raise "403" unless @item = @items.find(params[:id])
    render
  end

  private

  def set_items
    @items = @model.and_public
    if params[:controller] == 'sns/sys_notices'
      @items = @items.sys_admin_notice
    elsif params[:controller] == 'cms/sys_notices'
      @items = @items.cms_admin_notice
    elsif params[:controller] == 'gws/sys_notices'
      @items = @items.gw_admin_notice
    else
      @items = @model.none
    end
    @items
  end
end
