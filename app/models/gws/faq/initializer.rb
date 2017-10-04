module Gws::Faq
  class Initializer
    Gws::GroupSetting.plugin Gws::Faq::GroupSetting, ->{ gws_faq_setting_path }

    Gws::Role.permission :read_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :read_private_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :edit_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :edit_private_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :delete_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :delete_private_gws_faq_posts, module_name: 'gws/faq'

    Gws::Role.permission :read_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :read_private_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :edit_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :edit_private_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :delete_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :delete_private_gws_faq_categories, module_name: 'gws/faq'
  end
end
