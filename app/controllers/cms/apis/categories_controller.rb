class Cms::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Category::Node::Base

  public
    def index
      super
      @items = @items.sort_by(&:filename)
    end
end
