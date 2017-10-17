module Gws::Memo
  class Initializer
    Gws::Role.permission :read_other_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :read_private_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :edit_other_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :edit_private_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :delete_other_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :delete_private_gws_memo_messages, module_name: 'gws/memo'
  end
end
