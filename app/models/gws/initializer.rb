module Gws
  class Initializer
    Gws::Setting.plugin Gws::System::Setting, ->{ gws_system_setting_path }

    Gws::Role.permission :edit_gws_groups
    Gws::Role.permission :edit_gws_users
    Gws::Role.permission :edit_gws_user_titles
    Gws::Role.permission :edit_gws_roles
    Gws::Role.permission :read_gws_histories

    Gws::Role.permission :read_other_gws_custom_groups
    Gws::Role.permission :read_private_gws_custom_groups
    Gws::Role.permission :edit_other_gws_custom_groups
    Gws::Role.permission :edit_private_gws_custom_groups
    Gws::Role.permission :delete_other_gws_custom_groups
    Gws::Role.permission :delete_private_gws_custom_groups

    Gws::Role.permission :read_other_gws_notices
    Gws::Role.permission :read_private_gws_notices
    Gws::Role.permission :edit_other_gws_notices
    Gws::Role.permission :edit_private_gws_notices
    Gws::Role.permission :delete_other_gws_notices
    Gws::Role.permission :delete_private_gws_notices

    Gws::Role.permission :read_other_gws_links
    Gws::Role.permission :read_private_gws_links
    Gws::Role.permission :edit_other_gws_links
    Gws::Role.permission :edit_private_gws_links
    Gws::Role.permission :delete_other_gws_links
    Gws::Role.permission :delete_private_gws_links
  end
end
