FactoryBot.define do
  factory :chat_node_bot, class: Chat::Node::Bot, traits: [:cms_node] do
    route { "chat/bot" }
  end
end
