class Sns::SysNoticesController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'
  navi_view "sns/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.sys/notice"), action: :index]
  end

  public

  def index
    @items = @model.and_public.
      sys_admin_notice.
      search(params[:s]).
      reorder(notice_severity: 1, released: -1).
      page(params[:page]).per(50)
  end
end
