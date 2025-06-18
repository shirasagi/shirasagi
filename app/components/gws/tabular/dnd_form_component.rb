class Gws::Tabular::DndFormComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :object_name, :method_name, :options, :selected
end
