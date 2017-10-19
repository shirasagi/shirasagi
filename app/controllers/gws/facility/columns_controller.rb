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
end
