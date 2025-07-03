class Gws::Tabular::DndOrderFormComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :object_name, :method_name, :options, :selected
end
