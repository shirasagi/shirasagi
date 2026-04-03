class Sns::PublicNoticesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter
  include Sns::PublicNoticeFilter

  skip_before_action :logged_in?, only: [:index, :show, :frame_content]

  layout "ss/login"
  navi_view nil

  private

  def set_crumbs
    @crumbs = []
  end

  def set_items
    @items ||= @model.and_public.and_show_login
  end

  public

  def index
    set_items
    @items = @items.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
