class Gws::Board::Apis::BrowsingStatesController < ApplicationController
  include Gws::ApiFilter
  include Gws::BrowsingStateFilter

  model Gws::Board::Topic

  before_action :set_item

  private

  def set_item
    @item = @model.site(@cur_site).topic.find(params[:id])
  end
end
