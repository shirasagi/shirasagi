class Gws::Workflow2::Apis::FormCategoriesController < ApplicationController
  include Gws::ApiFilter
  include Gws::Apis::CategoryFilter

  model Gws::Workflow2::Form::Category
end
