class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  before_action :set_category

  private
    def set_crumbs
      set_category
      if @category.present?
        @crumbs << [:"mongoid.models.gws/share", gws_share_files_path]
        @crumbs << [@category.name, action: :index]
      else
        @crumbs << [:"mongoid.models.gws/share", action: :index]
      end
    end

    def set_category
      if params[:category].present?
        @category ||= Gws::Share::Category.site(@cur_site).where(id: params[:category]).first
      end
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def pre_params
      p = super
      if @category.present?
        p[:category_ids] = [ @category.id ]
      end
      p
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      if @category.present?
        params[:s] ||= {}
        params[:s][:site] = @cur_site
        params[:s][:category] = @category.name
      end

      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(_id: -1).
        page(params[:page]).per(50)
    end
end
