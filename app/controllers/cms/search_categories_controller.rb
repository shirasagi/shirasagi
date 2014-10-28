class Cms::SearchCategoriesController < ApplicationController
  include Cms::SearchCollectionFilter

  model Category::Node::Base
end
