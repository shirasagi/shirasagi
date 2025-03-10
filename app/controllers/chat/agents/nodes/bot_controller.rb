class Chat::Agents::Nodes::BotController < ApplicationController
  include Cms::NodeFilter::View

  protect_from_forgery except: [:line]
  after_action :create_chat_history
  after_action :render_translate, if: ->{ @translate_source && @translate_target }

  private

  def create_chat_history
    return if @result == @cur_node.first_text
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

  def render_translate
    converter = Translate::Converter.new(@cur_site, @translate_source, @translate_target)
    json_converter = Translate::JsonConverter::ChatBot.new(
      converter,
      response.body,
      ::File.join(@cur_site.translate_url, @translate_target.code))
    response.body = json_converter.convert
  end

  def format_suggests(suggests)
    return nil if suggests.blank?
    suggests.map { |text| { text: text, value: text } }
  end

  public

  def index
    value = params[:value].presence || params[:text]

    @intents = Chat::Intent.site(@cur_site).
      where(node_id: @cur_node.id).
      order_by(order: 1, name: 1, updated: -1).
      intents(value)

    if params[:question] == 'success'
      @results = [{ response: @cur_node.chat_success }]
    elsif params[:question] == 'retry'
      @results = [{ response: @cur_node.chat_retry }]
    elsif params[:text].present?
      @site_search_node = Cms::Node::SiteSearch.site(@cur_site).and_public(@cur_date).first
      if @site_search_node.present?
        uri = ::Addressable::URI.parse(@site_search_node.url)
        uri.query = { s: { keyword: value } }.to_query
      end
      if @intents.present?
        @results = @intents.collect do |intent|
          response = intent.response.presence || @cur_node.response_template
          question = @cur_node.question.presence if intent.question == 'enabled'
          url = uri.try(:to_s) if intent.site_search == 'enabled'
          {
            id: intent.id,
            suggests: format_suggests(intent.suggest),
            response: response,
            siteSearchUrl: url,
            question: question
          }
        end
      else
        @results = [{ response: @cur_node.exception_text, siteSearchUrl: uri.try(:to_s) }]
      end
    else
      @results = [{ suggests: format_suggests(@cur_node.first_suggest), response: @cur_node.first_text }]
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
