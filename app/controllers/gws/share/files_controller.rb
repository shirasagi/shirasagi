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
      @categories = Gws::Share::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
      if category_id = params[:category].presence
        @category ||= Gws::Share::Category.site(@cur_site).where(id: category_id).first
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
      if @category.present?
        params[:s] ||= {}
        params[:s][:site] = @cur_site
        params[:s][:category] = @category.name
      end

      @items = @model.site(@cur_site).
        readable(@cur_user, @cur_site).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item.readable?(@cur_user)
      render
    end
end
