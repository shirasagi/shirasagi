class Facility::SearchServicesController < ApplicationController
  include Cms::SearchFilter

  model Facility::Node::Service
end
