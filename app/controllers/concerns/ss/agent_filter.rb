module SS::AgentFilter
  extend ActiveSupport::Concern

  included do
    before_action :inherit_variables
  end

  private
    def controller
      @controller
    end

    def inherit_variables
      controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
        next if instance_variable_defined?(name)
        instance_variable_set name, controller.instance_variable_get(name)
      end
    end
end
