class Cms::Apis::NodesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  before_action :set_single
  before_action :set_model_from_param

  private
    def set_single
      @single = params[:single].present?
      @multi = !@single
    end

    def set_model_from_param
      model = params[:model].presence
      return if model.blank?
      return unless model.include?('::Node')

      model = model.constantize rescue nil
      return if model.blank?
      return unless model.ancestors.include?(Cms::Model::Node)

      @model = model
    end
end
