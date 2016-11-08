class Rss::Apis::WeatherXml::RegionsController < ApplicationController
  include Cms::ApiFilter

  model Rss::WeatherXml::Region

  before_action :set_single

  private
    def set_single
      @single = params[:single].present?
      @multi = !@single
    end

  public
    def index
      @items = @model.site(@cur_site).
        search(params[:s]).
        order_by(order: 1, _id: -1).
        page(params[:page]).per(50)
    end
end
