module Chat::Addon
  module Path
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :chat_path, type: String

      permit_params :chat_path
    end

    def chat_bot_node
      chat_node = Chat::Node::Bot.site(site).and_public.where(filename: chat_path.sub(/\A\//, '')).first
      chat_node ||= parent.becomes_with_route if parent.present?
      chat_node
    end
  end
end
