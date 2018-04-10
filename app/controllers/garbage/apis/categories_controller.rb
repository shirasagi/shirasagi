class Garbage::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Garbage::Node::Category
end
