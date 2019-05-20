module Chat
  class Initializer
    Cms::Part.plugin "chat/bot"

    Cms::Role.permission :edit_chat_bots
  end
end
