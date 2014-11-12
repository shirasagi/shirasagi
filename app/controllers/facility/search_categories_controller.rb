class Facility::SearchCategoriesController < ApplicationController
  include Cms::SearchFilter

  model Facility::Node::Category
end
