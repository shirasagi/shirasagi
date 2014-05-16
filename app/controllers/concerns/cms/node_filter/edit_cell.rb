# coding: utf-8
module Cms::NodeFilter::EditCell
  extend ActiveSupport::Concern
  include SS::CrudFilter
  
  included do
    helper ApplicationHelper
    helper Cms::FormHelper
    cattr_accessor :model_class
    before_action :inherit_variables
    before_action :set_model
    before_action :set_item
  end
  
  module ClassMethods
    def model(cls)
      self.model_class = cls if cls
    end
  end
  
  private
    def prepend_current_view_path
      prepend_view_path "app/cells/#{controller_path}"
    end
    
    def append_view_paths
      append_view_path "app/views/ss/crud"
    end
    
    def inherit_variables
      controller.instance_variables.select {|m| m =~ /^@[a-z]/ }.each do |name|
        next if instance_variable_defined?(name)
        instance_variable_set name, controller.instance_variable_get(name)
      end
      @base = @item
    end
    
    def set_model
      @model = self.class.model_class
      controller.instance_variable_set :@model, @model
    end
    
    def set_item
      @item = @base.new_record? ? @model.new(pre_params) : @model.unscoped.find(@base.id)
      @item.attributes = { route: @base.route }.merge(@fix_params)
      controller.instance_variable_set :@item, @item
    end
    
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }.merge(@fix_params)
    end
    
    def pre_params
      {}
    end
    
    def get_params
      params.require(:item).permit(@model.permitted_fields).merge(fix_params)
    end
    
  public
    def show
      raise "403" unless @item.allowed?(read: @cur_user)
      render
    end
    
    def new
      render
    end
    
    def create
      @item.attributes = get_params
      raise "403" unless @item.allowed?(create: @cur_user)
      @item.save ? @item : render(file: :new)
    end
    
    def edit
      raise "403" unless @item.allowed?(update: @cur_user)
      render
    end
    
    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(update: @cur_user)
      @item.update ? @item : render(file: :edit)
    end
    
    def delete
      raise "403" unless @item.allowed?(delete: @cur_user)
      render
    end
    
    def destroy
      raise "403" unless @item.allowed?(delete: @cur_user)
      @item.destroy ? @item : render(file: :delete)
    end
end
