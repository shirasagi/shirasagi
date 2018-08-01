module Gws::Presence
  class Initializer
    Gws::Role.permission :use_gws_user_presences, module_name: 'gws/presence'
    Gws::Role.permission :manage_private_gws_user_presences, module_name: 'gws/presence'
    Gws::Role.permission :manage_all_gws_user_presences, module_name: 'gws/presence'
    Gws::Role.permission :manage_custom_group_gws_user_presences, module_name: 'gws/presence'
  end
end
