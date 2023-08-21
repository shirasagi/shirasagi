module Gws::Portal
  class Initializer
    Gws::Group.include Gws::Portal::GroupExtension
    Gws::User.include Gws::Portal::UserExtension

    Gws::Role.permission :use_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :use_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :use_gws_portal_organization_settings, module_name: 'gws/portal'

    Gws::Role.permission :read_other_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :read_private_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :edit_other_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :edit_private_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :delete_other_gws_portal_user_settings, module_name: 'gws/portal'
    Gws::Role.permission :delete_private_gws_portal_user_settings, module_name: 'gws/portal'

    Gws::Role.permission :read_other_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :read_private_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :edit_other_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :edit_private_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :delete_other_gws_portal_group_settings, module_name: 'gws/portal'
    Gws::Role.permission :delete_private_gws_portal_group_settings, module_name: 'gws/portal'
  end
end
