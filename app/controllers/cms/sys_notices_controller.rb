class Cms::SysNoticesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'
  navi_view "cms/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.sys/notice"), action: :index]
  end

  def set_items
    @items ||= @model.and_public.cms_admin_notice
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
