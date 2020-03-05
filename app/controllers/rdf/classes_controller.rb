class Rdf::ClassesController < ApplicationController
  include Rdf::ObjectsFilter
  helper Cms::FormHelper

  model Rdf::Class
end
