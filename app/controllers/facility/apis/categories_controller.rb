class Facility::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Facility::Node::Category
end
