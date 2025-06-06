class Gws::Affair2::Admin::SpecialLeaveController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair2::SpecialLeave

  navi_view "gws/affair2/admin/main/navi"

  private

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair2_label || t('modules.gws/affair2/attendance'), gws_affair2_attendance_main_path ]
    @crumbs << [ t('modules.gws/affair2/admin/special_leave'), action: :index ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s])
  end
end
