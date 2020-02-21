class Chat::Agents::Parts::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    @chat_node = @cur_part.chat_bot_node
    @result = @chat_node.first_text
  end
end
