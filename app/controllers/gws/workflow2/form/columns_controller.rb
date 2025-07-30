class Gws::Workflow2::Form::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter2

  navi_view "gws/workflow2/main/navi"

  self.form_model = Gws::Workflow2::Form::Application

  private

  def set_crumbs
    @crumbs << [ t('modules.gws/workflow2'), gws_workflow2_setting_path ]
    @crumbs << [ t("gws/workflow2.navi.form.application"), gws_workflow2_form_forms_path ]
    @crumbs << [ cur_form.name, gws_workflow2_form_form_path(id: cur_form) ]
  end
end
