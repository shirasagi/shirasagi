class Guide2::Agents::Nodes::QuestionController < ApplicationController
  include Cms::NodeFilter::View

  public

  def index
    @item = @cur_node
  end

  def results
    @item = @cur_node

    ids = params[:ids].to_s rescue ''
    ids = ids.split(',')

    # yet
    @items = @item.guide2_results.select do |item|
      ids.include?(item.id.to_s)
    end
  end
end
