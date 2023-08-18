class Opendata::Apis::CategoriesController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Node::Category
end
