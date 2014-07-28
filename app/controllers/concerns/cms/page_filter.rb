# coding: utf-8
module Cms::PageFilter
  module ViewCell
    extend ActiveSupport::Concern

    included do
      helper ApplicationHelper
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
