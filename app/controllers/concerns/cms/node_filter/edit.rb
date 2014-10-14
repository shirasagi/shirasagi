module Cms::NodeFilter::Edit
  extend ActiveSupport::Concern
  include SS::AgentFilter
  include SS::CrudFilter

  included do
    helper Cms::FormHelper
    cattr_accessor :model_class
    before_action :set_model
    before_action :set_item
    after_action :reverse_item
  end

  module ClassMethods
    def model(cls)
      self.model_class = cls if cls
    end
  end

  private
    def prepend_current_view_path
      prepend_view_path "app/views/" + self.class.to_s.underscore.sub(/_\w+$/, "")
    end

    def inherit_variables
      super
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

    def reverse_item
      controller.instance_variable_set :@item, @item if @item
    end
end
