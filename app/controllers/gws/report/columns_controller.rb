class Gws::Report::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/report/main/navi"
  self.form_model = Gws::Report::Form

  private

  def set_deletable
    @deletable ||= @cur_form.allowed?(:delete, @cur_user, site: @cur_site, owned: true)
  end

  def set_crumbs
    set_form
    @crumbs << [@cur_site.menu_report_label || t('modules.gws/report'), gws_report_setting_path]
    @crumbs << [Gws::Report::Form.model_name.human, gws_report_forms_path]
    @crumbs << [@cur_form.name, gws_report_form_path(id: @cur_form)]
  end
end
