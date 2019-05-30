class Chat::Agents::Nodes::BotController < ApplicationController
  include Cms::PartFilter::View

  after_action :create_chat_history

  private

  def create_chat_history
    history = Chat::History.new(params.permit(Chat::History.permitted_fields))
    history.session_id = request.session.id
    history.request_id = request.uuid
    history.intent_id = @intent.try(:id)
    history.result = @result
    history.suggest = @intent.try(:suggest)
    history.site_id = @cur_site.id
    history.node_id = @cur_node.id
    history.save
  end

  public

  def index
    @intent = Chat::Intent.site(@cur_site).where(node_id: @cur_node.id).find_intent(params[:text])
    @result = if params[:text].present?
                @intent.try(:response).presence || @cur_node.becomes_with_route.exception_text
              else
                @cur_node.becomes_with_route.first_text
              end
  end
end
