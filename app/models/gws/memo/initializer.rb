module Gws::Memo
  class Initializer
    Gws::Role.permission :edit_private_gws_memo_messages, module_name: 'gws/memo'
  end
end
