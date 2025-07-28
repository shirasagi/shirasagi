class Gws::Workflow::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter2

  navi_view "gws/workflow/main/navi"

  self.form_model = Gws::Workflow::Form

  private

  def set_crumbs
    @crumbs << [ t('modules.gws/workflow'), gws_workflow_setting_path ]
    @crumbs << [ Gws::Workflow::Form.model_name.human, gws_workflow_forms_path ]
    @crumbs << [ cur_form.name, gws_workflow_form_path(id: cur_form) ]
  end
end
