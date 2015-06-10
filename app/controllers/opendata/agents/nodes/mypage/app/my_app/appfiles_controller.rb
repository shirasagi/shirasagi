class Opendata::Agents::Nodes::Mypage::App::MyApp::AppfilesController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::Mypage::MypageFilter
  helper Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_app
  before_action :set_model
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  protected
    def app
      @app ||= Opendata::App.site(@cur_site).find params[:app_id]
    end

    def set_app
      raise "403" if app.member_id != @cur_member.id
      @app_url  = "#{@cur_node.url}#{@app.id}/"
      @appfile_url = "#{@app_url}appfiles/"
    end

    def set_model
      @model = Opendata::Appfile
    end

    def set_item
      @item = app.appfiles.find params[:id]
      @item_url = "#{@appfile_url}#{@item.id}/"
    end

    def fix_params
      {}
    end

    def pre_params
      {}
    end

    def permit_fields
      @model.permitted_fields
    end

    def get_params
      params.require(:item).permit(permit_fields).merge(fix_params)
    end

  public
    def index
    @items = @app.appfiles.
      order_by(name: 1).
      page(params[:page]).per(50)

      render
    end

    def show
      render
    end

    def download
      @item = @app.appfiles.find(params[:appfile_id])

      send_file @item.file.path, type: @item.content_type, filename: @item.filename,
        disposition: :attachment, x_sendfile: true
    end

    def new
      @item = @model.new
      render
    end

    def create
      @item = @app.appfiles.new get_params

      if @item.save
        redirect_to "#{@app_url}appfiles/", notice: t("views.notice.saved")
      else
        render action: :new
      end
    end

    def edit
      render
    end

    def update
      @item.attributes = get_params

      if @item.update
        redirect_to "#{@app_url}appfiles/#{@item.id}/", notice: t("views.notice.saved")
      else
        render action: :edit
      end
    end

    def delete
      render
    end

    def destroy
      if @item.destroy
        redirect_to @app_url, notice: t("views.notice.deleted")
      else
        render action: :delete
      end
    end
end
