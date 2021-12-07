module Gws::Memo
  class Initializer
    Gws::User.include Gws::Memo::NoticeUserSetting

    Gws::Role.permission :edit_private_gws_memo_messages, module_name: 'gws/memo'
    #Gws::Role.permission :edit_private_gws_memo_notices, module_name: 'gws/memo/notice'

    Gws::Role.permission :read_other_gws_memo_lists, module_name: 'gws/memo'
    Gws::Role.permission :read_private_gws_memo_lists, module_name: 'gws/memo'
    Gws::Role.permission :edit_other_gws_memo_lists, module_name: 'gws/memo'
    Gws::Role.permission :edit_private_gws_memo_lists, module_name: 'gws/memo'
    Gws::Role.permission :delete_other_gws_memo_lists, module_name: 'gws/memo'
    Gws::Role.permission :delete_private_gws_memo_lists, module_name: 'gws/memo'

    Gws::Role.permission :read_other_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :read_private_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :edit_other_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :edit_private_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :delete_other_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :delete_private_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :send_other_gws_memo_list_messages, module_name: 'gws/memo'
    Gws::Role.permission :send_private_gws_memo_list_messages, module_name: 'gws/memo'

    Gws::Role.permission :read_other_gws_memo_categories, module_name: 'gws/memo'
    Gws::Role.permission :read_private_gws_memo_categories, module_name: 'gws/memo'
    Gws::Role.permission :edit_other_gws_memo_categories, module_name: 'gws/memo'
    Gws::Role.permission :edit_private_gws_memo_categories, module_name: 'gws/memo'
    Gws::Role.permission :delete_other_gws_memo_categories, module_name: 'gws/memo'
    Gws::Role.permission :delete_private_gws_memo_categories, module_name: 'gws/memo'

    Gws::Role.permission :read_other_gws_memo_templates, module_name: 'gws/memo'
    Gws::Role.permission :read_private_gws_memo_templates, module_name: 'gws/memo'
    Gws::Role.permission :edit_other_gws_memo_templates, module_name: 'gws/memo'
    Gws::Role.permission :edit_private_gws_memo_templates, module_name: 'gws/memo'
    Gws::Role.permission :delete_other_gws_memo_templates, module_name: 'gws/memo'
    Gws::Role.permission :delete_private_gws_memo_templates, module_name: 'gws/memo'

    Gws::Role.permission :restore_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :backup_gws_memo_messages, module_name: 'gws/memo'

    SS::File.model "gws/memo/message", Gws::File, permit: [:readable]
    SS::File.model "gws/memo/list_message", Gws::File, permit: [:readable, :role]

    Gws.module_usable :memo do |site, user|
      Gws::Memo.allowed?(:use, user, site: site)
    end
  end
end
