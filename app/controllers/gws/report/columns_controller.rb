class Gws::Report::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/main/conf_navi"
  self.form_model = Gws::Report::Form

  private

  def set_crumbs
    set_form
    @crumbs << [@cur_site.menu_report_label || t('modules.gws/report'), gws_report_setting_path]
    @crumbs << [Gws::Report::Form.model_name.human, gws_report_forms_path]
    @crumbs << [@cur_form.name, gws_report_form_path(id: @cur_form)]
  end
end
