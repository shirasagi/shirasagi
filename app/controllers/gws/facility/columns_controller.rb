class Gws::Facility::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view "gws/schedule/main/navi"

  self.form_model = Gws::Facility::Item

  private

  def set_crumbs
    set_form
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/facility.navi.item'), gws_facility_items_path]
    @crumbs << [@cur_form.name, gws_facility_item_path(id: @cur_form)]
  end

  public

  def input_form
    set_form
    @items = @cur_form.columns.order_by(order: 1, id: 1)

    render_opts = {}
    render_opts[:layout] = false if request.xhr?
    render_opts[:html] = '' if @items.blank?
    render(render_opts)
  end
end
