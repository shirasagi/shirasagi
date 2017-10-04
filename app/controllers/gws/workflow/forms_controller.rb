class Gws::Workflow::FormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::Form

  navi_view 'gws/workflow/settings/navi'

  private

  def set_crumbs
    @crumbs << [t('modules.gws/workflow'), gws_workflow_setting_path]
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
