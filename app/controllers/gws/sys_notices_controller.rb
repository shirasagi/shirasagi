class Gws::SysNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'

  private
    def set_crumbs
      @crumbs << [t("mongoid.models.sys/notice"), action: :index]
    end

  public
    def index
      @items = @model.and_public.
        gw_admin_notice.
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
