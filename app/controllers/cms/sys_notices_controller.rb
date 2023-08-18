class Cms::SysNoticesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'
  navi_view "cms/main/navi"

  private

  def set_item
    @item = @model.find(params[:id])
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_crumbs
    @crumbs << [t("mongoid.models.sys/notice"), action: :index]
  end

  public

  def index
    @items = @model.and_public.
      cms_admin_notice.
      search(params[:s]).
      reorder(notice_severity: 1, released: -1).
      page(params[:page]).per(50)
  end
end
