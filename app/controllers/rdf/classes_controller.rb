class Rdf::ClassesController < ApplicationController
  include Rdf::ObjectsFilter

  model Rdf::Class
end
