class Event::SearchCategoriesController < ApplicationController
  include Cms::SearchCollectionFilter

  model Category::Node::Base
end
