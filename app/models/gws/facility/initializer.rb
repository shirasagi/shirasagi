module Gws::Facility
  class Initializer
    Gws::GroupSetting.plugin Gws::Facility::GroupSetting, ->{ gws_facility_setting_path }

    Gws::Role.permission :read_other_gws_facility_items, module_name: 'gws/facility'
    Gws::Role.permission :read_private_gws_facility_items, module_name: 'gws/facility'
    Gws::Role.permission :edit_other_gws_facility_items, module_name: 'gws/facility'
    Gws::Role.permission :edit_private_gws_facility_items, module_name: 'gws/facility'
    Gws::Role.permission :delete_other_gws_facility_items, module_name: 'gws/facility'
    Gws::Role.permission :delete_private_gws_facility_items, module_name: 'gws/facility'

    Gws::Role.permission :read_other_gws_facility_categories, module_name: 'gws/facility'
    Gws::Role.permission :read_private_gws_facility_categories, module_name: 'gws/facility'
    Gws::Role.permission :edit_other_gws_facility_categories, module_name: 'gws/facility'
    Gws::Role.permission :edit_private_gws_facility_categories, module_name: 'gws/facility'
    Gws::Role.permission :delete_other_gws_facility_categories, module_name: 'gws/facility'
    Gws::Role.permission :delete_private_gws_facility_categories, module_name: 'gws/facility'
  end
end
