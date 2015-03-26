class Rdf::PropsController < ApplicationController
  include Rdf::ObjectsFilter

  model Rdf::Prop
end
