class Facility::Apis::ServicesController < ApplicationController
  include Cms::ApiFilter

  model Facility::Node::Service
end
