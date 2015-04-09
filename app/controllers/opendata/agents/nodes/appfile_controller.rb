class Opendata::Agents::Nodes::AppfileController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_app

  private
    def set_app
      @app_path = @cur_path.sub(/\/appfile\/.*/, ".html")

      @app = Opendata::App.site(@cur_site).public.
        filename(@app_path).
        first

      raise "404" unless @app
    end

  public
    def index
      redirect_to @app_path
    end

    def download
      @item = @app.appfiles.find_by id: params[:id], filename: params[:filename].force_encoding("utf-8")

      send_file @item.file.path, type: @item.content_type, filename: @item.filename,
        disposition: :attachment, x_sendfile: true
    end

    def content
      @cur_node.layout_id = nil

      @item = @app.appfiles.find_by id: params[:id], format: "CSV"

      render nothing: true unless @data = @item.parse_csv
    end
end
