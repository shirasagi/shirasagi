class Gws::SysNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.sys/notice", action: :index]
    end
end
