class Opendata::Apis::EstatCategoriesController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Node::EstatCategory
end
