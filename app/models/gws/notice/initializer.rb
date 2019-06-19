module Gws
  module Notice
    class Initializer
      Gws::Role.permission :read_other_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :read_private_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :edit_other_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :edit_private_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :delete_other_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :delete_private_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :trash_other_gws_notices, module_name: 'gws/notice'
      Gws::Role.permission :trash_private_gws_notices, module_name: 'gws/notice'

      Gws::Role.permission :read_other_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :read_private_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :edit_other_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :edit_private_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :delete_other_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :delete_private_gws_notice_folders, module_name: 'gws/notice'
      Gws::Role.permission :my_folder_private_gws_notice_folders, module_name: 'gws/notice'

      Gws::Role.permission :read_other_gws_notice_categories, module_name: 'gws/notice'
      Gws::Role.permission :read_private_gws_notice_categories, module_name: 'gws/notice'
      Gws::Role.permission :edit_other_gws_notice_categories, module_name: 'gws/notice'
      Gws::Role.permission :edit_private_gws_notice_categories, module_name: 'gws/notice'
      Gws::Role.permission :delete_other_gws_notice_categories, module_name: 'gws/notice'
      Gws::Role.permission :delete_private_gws_notice_categories, module_name: 'gws/notice'
    end
  end
end
