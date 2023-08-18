class Cms::Agents::Parts::HistoryListController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::HistoryListHelper

  def index
    @item = @cur_page || @cur_node
  end
end
