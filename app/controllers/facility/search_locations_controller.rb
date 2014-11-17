class Facility::SearchLocationsController < ApplicationController
  include Cms::SearchFilter

  model Facility::Node::Location
end
