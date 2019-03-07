module Gws::StaffRecord
  class Initializer
    Gws::Role.permission :use_gws_staff_record, module_name: 'gws/staff_record'

    Gws::Role.permission :read_other_gws_staff_record_years, module_name: 'gws/staff_record'
    Gws::Role.permission :read_private_gws_staff_record_years, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_other_gws_staff_record_years, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_years, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_other_gws_staff_record_years, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_private_gws_staff_record_years, module_name: 'gws/staff_record'

    Gws::Role.permission :read_other_gws_staff_record_groups, module_name: 'gws/staff_record'
    Gws::Role.permission :read_private_gws_staff_record_groups, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_other_gws_staff_record_groups, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_groups, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_other_gws_staff_record_groups, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_private_gws_staff_record_groups, module_name: 'gws/staff_record'

    Gws::Role.permission :read_other_gws_staff_record_users, module_name: 'gws/staff_record'
    Gws::Role.permission :read_private_gws_staff_record_users, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_other_gws_staff_record_users, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_users, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_other_gws_staff_record_users, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_private_gws_staff_record_users, module_name: 'gws/staff_record'

    Gws::Role.permission :read_other_gws_staff_record_seatings, module_name: 'gws/staff_record'
    Gws::Role.permission :read_private_gws_staff_record_seatings, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_other_gws_staff_record_seatings, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_seatings, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_other_gws_staff_record_seatings, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_private_gws_staff_record_seatings, module_name: 'gws/staff_record'

    Gws::Role.permission :read_other_gws_staff_record_user_titles, module_name: 'gws/staff_record'
    Gws::Role.permission :read_private_gws_staff_record_user_titles, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_other_gws_staff_record_user_titles, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_user_titles, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_other_gws_staff_record_user_titles, module_name: 'gws/staff_record'
    Gws::Role.permission :delete_private_gws_staff_record_user_titles, module_name: 'gws/staff_record'

    Gws::Role.permission :edit_other_gws_staff_record_charges, module_name: 'gws/staff_record'
    Gws::Role.permission :edit_private_gws_staff_record_charges, module_name: 'gws/staff_record'

    Gws.module_usable :staff_record do |site, user|
      Gws::StaffRecord.allowed?(:use, user, site: site)
    end
  end
end
