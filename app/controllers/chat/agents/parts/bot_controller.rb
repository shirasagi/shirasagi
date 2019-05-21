class Chat::Agents::Parts::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    if params[:text].present?
      @result = Chat::Intent.site(@cur_site).response(params[:text]).presence || @cur_part.exception_text
    else
      @result = @cur_part.first_text
    end
  end
end
