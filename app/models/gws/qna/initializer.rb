module Gws::Qna
  class Initializer
    Gws::Role.permission :use_gws_qna, module_name: 'gws/qna'

    Gws::Role.permission :read_other_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :read_private_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :edit_other_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :edit_private_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :delete_other_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :delete_private_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :trash_other_gws_qna_posts, module_name: 'gws/qna'
    Gws::Role.permission :trash_private_gws_qna_posts, module_name: 'gws/qna'

    Gws::Role.permission :read_other_gws_qna_categories, module_name: 'gws/qna'
    Gws::Role.permission :read_private_gws_qna_categories, module_name: 'gws/qna'
    Gws::Role.permission :edit_other_gws_qna_categories, module_name: 'gws/qna'
    Gws::Role.permission :edit_private_gws_qna_categories, module_name: 'gws/qna'
    Gws::Role.permission :delete_other_gws_qna_categories, module_name: 'gws/qna'
    Gws::Role.permission :delete_private_gws_qna_categories, module_name: 'gws/qna'

    Gws.module_usable :qna do |site, user|
      Gws::Qna.allowed?(:use, user, site: site)
    end
  end
end
