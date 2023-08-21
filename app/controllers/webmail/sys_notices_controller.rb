class Webmail::SysNoticesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.sys/notice"), action: :index]
  end

  public

  def index
    @items = @model.and_public.
      webmail_admin_notice.
      search(params[:s]).
      reorder(notice_severity: 1, released: -1).
      page(params[:page]).per(50)
  end
end
