class Webmail::SysNoticesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.sys/notice", action: :index]
    end

  public
    def index
      @items = @model.and_public.
        webmail_admin_notice.
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
