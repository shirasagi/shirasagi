class Cms::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  def index
    @items = @model.site(@cur_site).
      where(route: /^(category\/|opendata\/category)/).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
