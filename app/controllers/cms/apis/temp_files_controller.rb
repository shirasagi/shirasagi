class Cms::Apis::TempFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model Cms::TempFile

  def index
    @items = @model.site(@cur_site).
      where(:node_id.exists => false).
      allow(:read, @cur_user).
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  private
  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
