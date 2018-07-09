class Gws::Form::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/form/main/navi"
  self.form_model = Gws::Form::Form

  private

  def set_crumbs
    set_form
    @crumbs << [t('modules.gws/form'), gws_form_main_path]
    @crumbs << [t('ss.navi.editable'), gws_report_forms_path]
    @crumbs << [@cur_form.name, gws_form_editable_path(id: @cur_form)]
  end

  def set_form
    @cur_form ||= form_model.site(@cur_site).find(params[:editable_id])
  end
end
