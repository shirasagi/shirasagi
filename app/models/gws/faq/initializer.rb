module Gws::Faq
  class Initializer
    Gws::Role.permission :use_gws_faq, module_name: 'gws/faq'

    Gws::Role.permission :read_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :read_private_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :edit_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :edit_private_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :delete_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :delete_private_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :trash_other_gws_faq_posts, module_name: 'gws/faq'
    Gws::Role.permission :trash_private_gws_faq_posts, module_name: 'gws/faq'

    Gws::Role.permission :read_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :read_private_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :edit_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :edit_private_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :delete_other_gws_faq_categories, module_name: 'gws/faq'
    Gws::Role.permission :delete_private_gws_faq_categories, module_name: 'gws/faq'

    Gws.module_usable :faq do |site, user|
      Gws::Faq.allowed?(:use, user, site: site)
    end
  end
end
