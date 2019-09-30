class Gws::Affair::DutyNoticesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::DutyNotice

  navi_view "gws/affair/main/navi"

  before_action :set_crumbs

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/duty_notice"), gws_affair_duty_notices_path ]
  end
end
