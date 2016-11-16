class Rss::Apis::WeatherXml::FloodRegionsController < ApplicationController
  include Cms::ApiFilter

  model Rss::WeatherXml::WaterLevelStation

  before_action :set_single

  private
    def set_single
      @single = params[:single].present?
      @multi = !@single
    end

  public
  def index
    @items = @model.site(@cur_site).
      and_enabled.
      search(params[:s]).
      order_by(order: 1, _id: 1).
      page(params[:page]).per(50)
  end
end
