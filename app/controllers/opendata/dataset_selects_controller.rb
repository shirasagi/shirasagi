class Opendata::DatasetSelectsController < ApplicationController
  include Opendata::AjaxFilter

  before_action :set_site

  private
    def set_site
      host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"]
      @cur_site ||= SS::Site.find_by_domain host


      @model = Opendata::Dataset
    end

  public
    def index
      @items = @model.site(@cur_site).search(params[:s]).order_by(_id: -1)
    end
end
