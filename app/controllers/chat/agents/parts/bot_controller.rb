class Chat::Agents::Parts::BotController < ApplicationController
  include Cms::PartFilter::View

  def index
    @chat_node = Chat::Node::Bot.site(@cur_site).and_public(@cur_date).where(filename: @cur_part.chat_path.sub(/\A\//, '')).first
    @chat_node ||= @cur_part.parent.becomes_with_route
    @result = @chat_node.first_text
  end
end
