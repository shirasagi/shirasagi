class Opendata::AppscriptsController < ApplicationController
  include Opendata::MypageFilter

  before_action :set_site
  before_action :set_app, only: [:show_point, :add_point, :point_members]
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

    def set_app
      @app_path = "#{params[:app]}.html"

      @app = Opendata::App.site(@cur_site).public.filename(@app_path).first

      raise "404" unless @app
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
        @app_index = "/app/#{@item.id}/appfile/#{@app_html.filename}"

        @sample = @item.appfiles.where(format: "CSV")
      end

      if @item.dataset_ids.empty? == false
        @ds = Opendata::Dataset.find(@item.dataset_ids)
      end
    end

    def show_point
      @cur_node.layout = nil
      @mode = nil

      if logged_in?(redirect: false)
        @mode = :add

        cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }
        @mode = :cancel if point = Opendata::AppPoint.where(cond).first
      end
    end

    def add_point
      @cur_node.layout = nil
      raise "403" unless logged_in?(redirect: false)

      cond = { site_id: @cur_site.id, member_id: @cur_member.id, app_id: @app.id }

      if point = Opendata::AppPoint.where(cond).first
        point.destroy
        @app.inc point: -1
        @mode = :add
      else
        Opendata::AppPoint.new(cond).save
        @app.inc point: 1
        @mode = :cancel
      end

      render :show_point
    end

    def point_members
      @cur_node.layout = nil
      @items = Opendata::AppPoint.where(site_id: @cur_site.id, app_id: @app.id)
    end

end
