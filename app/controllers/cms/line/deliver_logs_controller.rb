class Cms::Line::DeliverLogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::SnsPostLog::LineDeliver

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_deliver_log"), cms_line_deliver_logs_path]
  end
end
