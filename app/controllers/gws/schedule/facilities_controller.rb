class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter

  model Gws::Schedule::Facility
end
