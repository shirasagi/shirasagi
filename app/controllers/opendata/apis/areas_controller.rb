class Opendata::Apis::AreasController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Node::Area
end
