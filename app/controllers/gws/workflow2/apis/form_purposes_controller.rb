class Gws::Workflow2::Apis::FormPurposesController < ApplicationController
  include Gws::ApiFilter
  include Gws::Apis::CategoryFilter

  model Gws::Workflow2::Form::Purpose
end
