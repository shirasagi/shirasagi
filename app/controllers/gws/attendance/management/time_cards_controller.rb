class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard
end
