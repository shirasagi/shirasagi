class Multilingual::PagesController < ApplicationController
  include Cms::BaseFilter
  include Multilingual::PageFilter

  append_view_path "app/views/cms/pages"
  navi_view "cms/main/navi"
  lang_view "multilingual/pages/lang"

  before_action :set_native_item
  before_action :set_model
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_filename
  before_action :set_item_attributes, only: [:show, :edit, :update, :delete, :destroy]

  public
    def index
      @items = []

      foreign_item = @native_item.foreign(params[:lang])
      if foreign_item
        @items << foreign_item
        @items = @items + foreign_item.branches
      end
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
      @native_item = Cms::Page.find(params[:native_id]).becomes_with_route
    end

    def set_model
      @model = @native_item.class
    end

    def set_filename
      if @item.try(:branch?)
        @filename = @item.filename
      else
        @filename = "#{params[:lang]}/#{@native_item.filename}"
      end
    end

    def set_item
      @item = @model.find params[:id]
    end

    def set_item_attributes
      @item.attributes = fix_params
    end
end
