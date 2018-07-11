class Gws::Questionnaire::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/questionnaire/main/navi"
  self.form_model = Gws::Questionnaire::Form

  private

  def set_crumbs
    set_form
    @crumbs << [t('modules.gws/questionnaire'), gws_questionnaire_main_path]
    @crumbs << [t('ss.navi.editable'), gws_questionnaire_editables_path]
    @crumbs << [@cur_form.name, gws_questionnaire_editable_path(id: @cur_form)]
  end

  def set_form
    @cur_form ||= form_model.site(@cur_site).find(params[:editable_id])
  end
end
