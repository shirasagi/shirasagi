class Gws::Survey::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/survey/main/navi"
  self.form_model = Gws::Survey::Form

  private

  def set_crumbs
    set_form
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('ss.navi.editable'), gws_survey_editables_path]
    @crumbs << [@cur_form.name, gws_survey_editable_path(id: @cur_form)]
  end

  def set_form
    @cur_form ||= form_model.site(@cur_site).find(params[:editable_id])
  end
end
