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
    return if params[:model].blank?

    model = params[:model].constantize rescue nil
    return if model.nil?
    return if !model.include?(Cms::Model::Node)

    @model = model
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)

    if params[:layout] == "iframe"
      render layout: "ss/ajax_in_iframe"
    end
  end
end
