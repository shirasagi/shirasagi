class Cms::Line::MailHandlersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::MailHandler

  navi_view "cms/line/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [t("cms.line_mail_handlers"), cms_line_mail_handlers_path]
  end
end
