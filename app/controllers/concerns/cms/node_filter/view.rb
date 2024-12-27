module Cms::NodeFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter
  include Cms::FeedFilter

  included do
    helper Cms::PublicHelper
    helper Map::MapHelper
    cattr_accessor :model_class
    before_action :set_model
  end

  module ClassMethods
    def model(cls)
      self.model_class = cls if cls
    end
  end

  private

  def set_model
    @model = self.class.model_class
    if controller
      controller.instance_variable_set :@model, @model
    end
  end

  def render_with_pagination(items)
    raise SS::NotFoundError if params[:page].to_i > 1 && items.empty?
    render
  end
end
