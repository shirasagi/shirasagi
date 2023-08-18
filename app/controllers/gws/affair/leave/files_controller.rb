class Gws::Affair::Leave::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::FileFilter
  include Gws::Affair::WorkflowFilter

  model Gws::Affair::LeaveFile

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/leave'), gws_affair_leave_main_path]
    if %w(mine approve all).include?(params[:state])
      @crumbs << [
        t("modules.gws/affair/overtime/file/#{params[:state]}"),
        gws_affair_leave_files_path(state: params[:state])
      ]
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
