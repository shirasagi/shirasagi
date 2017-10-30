class Gws::Facility::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view 'gws/facility/settings/navi'
  self.form_model = Gws::Facility::Item

  private

  def set_crumbs
    set_form
    @crumbs << [t('mongoid.models.gws/facility/group_setting'), gws_facility_items_path]
    @crumbs << [t('mongoid.models.gws/facility/group_setting/item'), gws_facility_items_path]
    @crumbs << [@cur_form.name, gws_facility_item_path(id: @cur_form)]
  end

  public

  def input_form
    set_form
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)
    @items = @cur_form.columns.order_by(order: 1, id: 1)

    render_opts = {}
    render_opts[:layout] = false if request.xhr?
    render_opts[:html] = '' if @items.blank?
    render(render_opts)
  end
end
