# coding: utf-8
module Cms::PartFilter::ViewCell
  extend ActiveSupport::Concern
  
  included do
    helper ApplicationHelper
    before_action :prepend_current_view_path
    before_action :inherit_variables
    before_action :set_item
  end
  
  private
    def prepend_current_view_path
      prepend_view_path "app/cells/#{controller_path}"
    end
    
    def inherit_variables
      controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
        next if instance_variable_defined?(name)
        instance_variable_set name, controller.instance_variable_get(name)
      end
      
      @request_url ||= params[:ref]
      @request_url.sub!(/\.kana\.html$/, ".html") if @request_url
    end
    
    def set_item
      @cur_part = @cur_part.becomes_with_route
    end
    
    def redirect_to(*args)
      controller.redirect_to(*args)
    end
end
