class Multilingual::Node::PartsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PartFilter

  append_view_path "app/views/cms/pages"
  navi_view "cms/main/navi"
  lang_view "multilingual/parts/lang"

  before_action :set_native_item
  before_action :set_model
  before_action :set_filename
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]

  public
    def index
      @items = []

      foreign_item = @native_item.foreign(params[:lang])
      @items << foreign_item if foreign_item
    end

  private
    #def pre_params
    #  action_name == "new" ? @native_item.attributes : {}
    #end

    def fix_params
      {
        cur_user: @cur_user, cur_site: @cur_site,
        filename: @filename, basename: nil,
        native_id: @native_item.id
      }
    end

    def set_native_item
      @native_item = Cms::Part.find(params[:native_id]).becomes_with_route
    end

    def set_model
      @model = @native_item.class
    end

    def set_filename
      @filename = "#{params[:lang]}/#{@native_item.filename}"
    end

    def set_item
      @item = @model.find params[:id]
      @item.attributes = fix_params
    end
end
