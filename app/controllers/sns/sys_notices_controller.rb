class Sns::SysNoticesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include Sns::PublicNoticeFilter

  append_view_path 'app/views/sns/public_notices'
  navi_view "sns/main/navi"
end
