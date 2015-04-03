class Facility::Apis::LocationsController < ApplicationController
  include Cms::ApiFilter

  model Facility::Node::Location
end
