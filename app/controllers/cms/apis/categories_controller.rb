class Cms::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  private

  def set_items
    @items ||= @model.site(@cur_site).where(route: /^(category\/|opendata\/category)/)
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    set_items
    @items = @items.
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
