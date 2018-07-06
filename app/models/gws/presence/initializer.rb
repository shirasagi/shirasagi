module Gws::Presence
  class Initializer
    Gws::Role.permission :edit_private_gws_user_presences, module_name: 'gws/presence'
    Gws::Role.permission :edit_other_gws_user_presences, module_name: 'gws/presence'
  end
end
