module SS::CellFilter
  extend ActiveSupport::Concern

  def inherit_variables
    controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
      next if instance_variable_defined?(name)
      instance_variable_set name, controller.instance_variable_get(name)
    end
  end
end
