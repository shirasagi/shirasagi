class Cms::Apis::UserFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::UserFile

  private

  def fix_params
    h = { cur_user: @cur_user }
    h[:unnormalize] = true if params[:unnormalize].present?
    h
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
end
