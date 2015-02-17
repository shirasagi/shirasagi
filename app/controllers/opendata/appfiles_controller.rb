class Opendata::AppfilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper Opendata::FormHelper

  model Opendata::Appfile

  navi_view "opendata/main/navi"

  before_action :set_app

  private
    def app
      @app ||= Opendata::App.site(@cur_site).node(@cur_node).find params[:app_id]
    end

    def set_app
      raise "403" unless app.allowed?(:edit, @cur_user, site: @cur_site)
      @crumbs << [@app.name, opendata_app_path(id: @app)]
    end

    def set_item
      @item = app.appfiles.find params[:id]
    end

  public
    def index
      @items = @app.appfiles.
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def create
      @item = @app.appfiles.create get_params
      render_create @item.valid?
    end

    def download
      @item = @app.appfiles.find params[:appfile_id]
      send_file @item.file.path, type: @item.content_type, filename: @item.filename,
        disposition: :attachment, x_sendfile: true
    end

end
