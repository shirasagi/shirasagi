module Chat
  class Initializer
    Cms::Node.plugin "chat/bot"
    Cms::Part.plugin "chat/bot"

    Cms::Role.permission :delete_other_chat_bots
    Cms::Role.permission :delete_private_chat_bots
    Cms::Role.permission :edit_other_chat_bots
    Cms::Role.permission :edit_private_chat_bots
    Cms::Role.permission :read_other_chat_bots
    Cms::Role.permission :read_private_chat_bots
    Cms::Role.permission :import_other_chat_bots
    Cms::Role.permission :import_private_chat_bots
  end
end
