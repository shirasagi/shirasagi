class Chat::Agents::Nodes::BotController < ApplicationController
  include Cms::PartFilter::View

  protect_from_forgery except: [:line]
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
    @cur_node = @cur_node.becomes_with_route
    @intents = Chat::Intent.site(@cur_site).
      where(node_id: @cur_node.id).
      order_by(order: 1, name: 1, updated: -1).
      intents(params[:text])
    if params[:question] == 'success'
      @results = [{ response: @cur_node.chat_success }]
    elsif params[:question] == 'retry'
      @results = [{ response: @cur_node.chat_retry }]
    elsif params[:text].present?
      @site_search_node = Cms::Node::SiteSearch.site(@cur_site).and_public(@cur_date).first
      if @site_search_node.present?
        uri = URI.parse(@site_search_node.url)
        uri.query = { s: { keyword: params[:text] } }.to_query
      end
      if @intents.present?
        @results = @intents.collect do |intent|
          response = intent.response.presence || @cur_node.response_template
          question = @cur_node.question.presence if intent.question == 'enabled'
          url = uri.try(:to_s) if intent.site_search == 'enabled'
          {
            id: intent.id, suggests: intent.suggest.presence, response: response, 'siteSearchUrl' => url,
            question: question
          }
        end
      else
        @results = [{ response: @cur_node.exception_text, 'siteSearchUrl' => uri.try(:to_s) }]
      end
    else
      @results = [{ suggests: @cur_node.first_suggest.presence, response: @cur_node.first_text }]
    end
  end

  def line
    service = Chat::LineBot::Service.new(cur_site: @cur_site, cur_node: @cur_node, request: request)
    unless service.valid?
      head :bad_request
      return
    end
    service.call
    head :ok
  end
end
