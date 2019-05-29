class Chat::Agents::Nodes::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    @intent = Chat::Intent.site(@cur_site).where(node_id: @cur_node.id).find_intent(params[:text])
    @result = if params[:text].present?
                @intent.try(:response).presence || @cur_node.becomes_with_route.exception_text
              else
                @cur_node.becomes_with_route.first_text
              end
  end
end
