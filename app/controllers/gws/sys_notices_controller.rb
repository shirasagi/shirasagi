class Gws::SysNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.sys/notice"), action: :index]
  end

  def set_items
    @items ||= @model.and_public.gw_admin_notice
  end

  public

  def index
    set_items
    @items = @items.
      search(params[:s]).
      reorder(notice_severity: 1, released: -1).
      page(params[:page]).per(50)
  end
end
