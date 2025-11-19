class Sys::ImageResizesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model SS::ImageResize

  menu_view "sys/crud/menu"

  private

  def set_crumbs
    @crumbs << [t("sys.image_resize"), sys_image_resize_path]
  end

  def set_item
    raise "403" unless @model.allowed?(:edit, @cur_user)
    @item ||= begin
      criteria = @model.all
      criteria = criteria.reorder(order: 1, name: 1, _id: -1)
      item = criteria.first
      item ||= @model.new(state: SS::ImageResize::STATE_DISABLED)
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def crud_redirect_url
    url_for(action: :show)
  end
end
