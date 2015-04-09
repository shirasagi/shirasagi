class Opendata::AppscriptsController < ApplicationController
  include Opendata::MypageFilter

  before_action :set_site
  before_action :set_file, only: [:index, :text]
  skip_filter :logged_in?

  private
    def set_site
      host = request.env["HTTP_X_FORWARDED_HOST"] || request.env["HTTP_HOST"]
      @cur_site ||= SS::Site.find_by_domain host
    end

    def set_file
      item = Opendata::App.find(params[:app])

      filename = params[:filename] + "." + params[:format]
      @appfile = item.appfiles.where(filename: filename).first
    end

  public
    def index
      if @appfile.present?
        send_file @appfile.file.path, type: @appfile.content_type, filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end

    def text
      if @appfile.present?
        send_file @appfile.file.path, :type => "text/plain", filename: @appfile.filename,
          disposition: :inline, x_sendfile: true
      end
    end

    def full
      @item = Opendata::App.find(params[:app])

      @app_html = @item.appfiles.where(filename: "index.html").first
      if @app_html.present?
        @app_index = "/app/#{@item.id}/application/#{@app_html.filename}"
      end

    end

end
