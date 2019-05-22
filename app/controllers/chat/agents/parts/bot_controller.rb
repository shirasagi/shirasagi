class Chat::Agents::Parts::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    @intent = Chat::Intent.site(@cur_site).find_intent(params[:text])
    @result = if params[:text].present?
      @intent.try(:response).presence || @cur_part.exception_text
    else
      @cur_part.first_text
    end
  end
end
