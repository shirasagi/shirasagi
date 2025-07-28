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
    models = Mongoid.models.select { |m| m.ancestors.include?(Cms::Model::Node) }
    model = models.find{ |m| m.to_s == params[:model] }
    return unless model

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

  def routes
    @single = params[:single].present?
    @multi = !@single

    @items = Cms::Node.new.route_options
  end
end
