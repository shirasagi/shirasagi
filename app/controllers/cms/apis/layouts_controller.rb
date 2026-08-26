class Cms::Apis::LayoutsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Layout

  def index
    set_items
    @items = @items.
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
