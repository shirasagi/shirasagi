class Cms::Apis::UserFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::UserFile

  private

  def fix_params
    { cur_user: @cur_user }
  end

  def set_items
    @items ||= @model.user(@cur_user)
  end

  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    set_items
    @items = @items.
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def select
    select_with_clone
  end

  def selected_files
    @select_ids = params[:select_ids].to_a
    set_items
    @items = @items.
      in(id: @select_ids).
      order_by(filename: 1)
    render template: "index"
  end
end
