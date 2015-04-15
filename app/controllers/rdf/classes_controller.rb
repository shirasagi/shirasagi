class Rdf::ClassesController < ApplicationController
  include Rdf::ObjectsFilter
  helper Opendata::FormHelper

  model Rdf::Class
end
