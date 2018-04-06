class Garbage::SearchCategoriesController < ApplicationController
  include Cms::ApiFilter

  model Garbage::Node::Category
end
