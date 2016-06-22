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

    def filters
      @filters ||= begin
        request.env["ss.filters"] ||= []
      end
    end

    def mobile_path?
      filters.include?(:mobile)
    end

    def preview_path?
      filters.include?(:preview)
    end

    def javascript_configs
      controller.javascript_configs
    end

    def javascript_config(conf)
      controller.javascript_config(conf)
    end
end
