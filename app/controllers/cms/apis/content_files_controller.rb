class Cms::Apis::ContentFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model SS::File

  private

  def fix_params
    { cur_user: @cur_user }
  end

  def set_item
    @item = @model.where(site_id: @cur_site.id).find(params[:id])
    @item = @item.becomes_with_model
    @item.attributes = fix_params
    @item.cur_site = @cur_site if @item.respond_to?(:cur_site=)
    @item.cur_group = @cur_group if @item.respond_to?(:cur_group=)
    @item
  end
end
