# coding: utf-8
module SS::AddonFilter
  module Layout
    extend ActiveSupport::Concern
    include SS::LayoutFilter
    
    included do
      after_action :inherit_layout
    end
    
    def inherit_layout
      stylesheets.each do |path|
        controller.stylesheets << path unless controller.stylesheets.include?(path)
      end
      javascripts.each do |path|
        ctrl = controller.is_a?(Cell::Rails) ? controller.controller : controller
        ctrl.javascripts << path unless ctrl.javascripts.include?(path)
      end
    end
  end
  
  module EditCell
    extend ActiveSupport::Concern
    include SS::AddonFilter::Layout
    
    included do
      helper ApplicationHelper
      helper EditorHelper
      helper AddonHelper
      before_action :inherit_variables
    end
    
    private
      def inherit_variables
        controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
          next if instance_variable_defined?(name)
          instance_variable_set name, controller.instance_variable_get(name)
        end
      end
      
    public
      def show
        render partial: "show"
      end
      
      def new
        render partial: "form"
      end
      
      def create
        render partial: "form"
      end
      
      def edit
        render partial: "form"
      end
      
      def update
        render partial: "form"
      end
  end
  
  module ViewCell
    extend ActiveSupport::Concern
    
    included do
      helper ApplicationHelper
      helper EditorHelper
      before_action :inherit_variables
    end
    
    private
      def inherit_variables
        controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
          next if instance_variable_defined?(name)
          instance_variable_set name, controller.instance_variable_get(name)
        end
      end
      
    public
      def index
        render
      end
  end
end
