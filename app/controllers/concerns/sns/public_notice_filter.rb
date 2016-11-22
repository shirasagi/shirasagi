module Sns::PublicNoticeFilter
  extend ActiveSupport::Concern

  included do
    model Sys::Notice
  end

  def index
    @items = @model.and_public.
      sys_admin_notice.
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item = @model.and_public.find(params[:id])
    render
  end
end
