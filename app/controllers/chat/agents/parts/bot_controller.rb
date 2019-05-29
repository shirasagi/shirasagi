class Chat::Agents::Parts::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    @chat_node = Chat::Node::Bot.site(@cur_site).and_public(@cur_date).where(filename: @cur_part.chat_path).first ||
                 @cur_part.parent.becomes_with_route
    @intent = Chat::Intent.site(@cur_site).where(node_id: @chat_node.id).find_intent(params[:text])
    @result = if params[:text].present?
                @intent.try(:response).presence || @chat_node.exception_text
              else
                @chat_node.first_text
              end
  end
end
