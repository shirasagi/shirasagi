class Opendata::AppsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper Opendata::FormHelper

  model Opendata::App

  append_view_path "app/views/cms/pages"
  navi_view "opendata/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      @items = @model.site(@cur_site).node(@cur_node).allow(:read, @cur_user).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def download
      @item = @model.find params[:app_id]
      #@file = SS::File.find @item.file_id
      #send_file @file.path, type: @file.content_type, filename: @item.appfilename,
      send_file @item.path, type: @item.content_type, filename: @item.appfilename,
        disposition: :attachment, x_sendfile: true
    end

end
