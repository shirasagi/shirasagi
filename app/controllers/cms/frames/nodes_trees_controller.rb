class Cms::Frames::NodesTreesController < ApplicationController
  include Cms::BaseFilter

  model Cms::Node

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(depth: 1).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
      
    render :index, layout: false
  end
end
