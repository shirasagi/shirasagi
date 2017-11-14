module Gws::Circular
  class Initializer
    Gws::GroupSetting.plugin Gws::Circular::GroupSetting, ->{ gws_circular_setting_path }

    Gws::Role.permission :read_other_gws_circular_posts, module_name: 'gws/circular'
    Gws::Role.permission :read_private_gws_circular_posts, module_name: 'gws/circular'
    Gws::Role.permission :edit_other_gws_circular_posts, module_name: 'gws/circular'
    Gws::Role.permission :edit_private_gws_circular_posts, module_name: 'gws/circular'
    Gws::Role.permission :delete_other_gws_circular_posts, module_name: 'gws/circular'
    Gws::Role.permission :delete_private_gws_circular_posts, module_name: 'gws/circular'
  end
end
