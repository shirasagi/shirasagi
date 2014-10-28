class Cms::SearchCategoriesController < ApplicationController
  include Cms::SearchFilter

  model Category::Node::Base
end
