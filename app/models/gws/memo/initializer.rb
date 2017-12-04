module Gws::Memo
  class Initializer
    Gws::GroupSetting.plugin Gws::Memo::GroupSetting, ->{ gws_memo_setting_path }
    Gws::Role.permission :read_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :edit_gws_memo_messages, module_name: 'gws/memo'
    Gws::Role.permission :delete_gws_memo_messages, module_name: 'gws/memo'
  end
end
