class Cms::SnsPost::LogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::SnsPostLog::Base

  navi_view "cms/sns_post/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.sns_post"), cms_sns_post_logs_path]
  end
end
