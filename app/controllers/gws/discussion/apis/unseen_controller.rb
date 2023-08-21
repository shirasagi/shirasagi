class Gws::Discussion::Apis::UnseenController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Topic

  def index
    @item = @model.find(params[:id])
    render plain: @item.descendants_updated.to_i
  end
end
