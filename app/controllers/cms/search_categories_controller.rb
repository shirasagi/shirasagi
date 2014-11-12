class Cms::SearchCategoriesController < ApplicationController
  include Cms::SearchFilter

  model Category::Node::Base

  public
    def index
      super
      @items = @items.sort_by(&:filename)
    end
end
