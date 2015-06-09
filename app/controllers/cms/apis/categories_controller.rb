class Cms::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Category::Node::Base

  public
    def index
      @items = @model.site(@cur_site).
        search(params[:s]).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end
end
