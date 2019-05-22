class Chat::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Chat::Category

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end
end
