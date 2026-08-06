class Jmaxml::Apis::QuakeRegionsController < ApplicationController
  include Cms::ApiFilter

  model Jmaxml::QuakeRegion

  before_action :set_single

  private

  def set_single
    @single = params[:single].present?
    @multi = !@single
  end

  def set_items
    @items ||= @model.site(@cur_site).and_enabled
  end

  public

  def index
    set_items
    @items = @items.
      search(params[:s]).
      order_by(order: 1, _id: 1).
      page(params[:page]).per(50)
  end
end
