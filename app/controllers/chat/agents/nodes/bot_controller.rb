class Chat::Agents::Nodes::BotController < ApplicationController
  include Cms::PartFilter::View

  after_action :create_chat_history

  private

  def create_chat_history
    return if @result == @cur_node.becomes_with_route.first_text
    history = Chat::History.new(params.permit(Chat::History.permitted_fields))
    history.session_id = request.session.id
    history.request_id = request.uuid
    history.prev_intent_id = Chat::History.site(@cur_site).
      where(node_id: @cur_node.id, session_id: history.session_id).
      order_by(created: -1).first.try(:intent).try(:id)
    history.intent_id = @intent.try(:id)
    history.result = @result
    history.suggest = @intent.try(:suggest)
    history.click_suggest = params[:text] if params[:click_suggest].present?
    history.site_id = @cur_site.id
    history.node_id = @cur_node.id
    history.save
  end

  public

  def index
    @intent = Chat::Intent.site(@cur_site).
      where(node_id: @cur_node.id).
      order_by(order: 1, updated: -1).
      find_intent(params[:text])
    if params[:question] == 'success'
      @result = @cur_node.becomes_with_route.chat_success
    elsif params[:question] == 'retry'
      @result = @cur_node.becomes_with_route.chat_retry
    elsif params[:text].present?
      if @intent.present?
        @suggest = @intent.suggest
        @result = @intent.response.presence || @cur_node.becomes_with_route.response_template
      else
        @result = @cur_node.becomes_with_route.exception_text
      end
    else
      @suggest = @cur_node.becomes_with_route.first_suggest
      @result = @cur_node.becomes_with_route.first_text
    end
  end
end
