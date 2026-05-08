class Cms::Line::EventSessionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::EventSession

  navi_view "cms/line/main/navi"

  private

  def fix_params
    { cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [t("cms.line"), cms_line_messages_path]
    @crumbs << [t("cms.line_event_session"), cms_line_event_sessions_path]
  end
end
