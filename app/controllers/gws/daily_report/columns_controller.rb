class Gws::DailyReport::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter2

  navi_view "gws/daily_report/main/navi"

  self.form_model = Gws::DailyReport::Form

  private

  def set_crumbs
    set_form
    @crumbs << [t('modules.gws/daily_report'), gws_daily_report_main_path]
    @crumbs << [Gws::DailyReport::Form.model_name.human, gws_daily_report_forms_path]
    @crumbs << [@cur_form.name, gws_daily_report_form_path(id: @cur_form)]
  end
end
