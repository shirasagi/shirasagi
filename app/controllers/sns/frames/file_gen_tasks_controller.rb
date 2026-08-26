class Sns::Frames::FileGenTasksController < ApplicationController
  include Sns::BaseFilter
  include SS::AjaxFilter

  model SS::FileGenTask
  layout "ss/item_frame"

  private

  def set_item
    @item ||= @model.where(user_id: @cur_user).find(params[:id])
  end

  public

  def status
    set_item
    render
  end
end
