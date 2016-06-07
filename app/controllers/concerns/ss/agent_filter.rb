module SS::AgentFilter
  extend ActiveSupport::Concern
  include SS::TransSidFilter

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

  public
    def stylesheets
      controller.stylesheets
    end

    def stylesheet(path)
      controller.stylesheet(path)
    end

    def javascripts
      controller.javascripts
    end

    def javascript(path)
      controller.javascript(path)
    end
end
