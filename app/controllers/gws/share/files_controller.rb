class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File
  before_action :set_category

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share", action: :index]
    end

    def set_category
      if params[:category].present?
        @category ||= Gws::Share::Category.site(@cur_site).where(name: params[:category].sub(/^\//, '')).first
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

      if params[:category].present?
        params[:s] ||= {}
        params[:s][:site] = @cur_site
        params[:s][:category] = params[:category]
      end

      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(_id: -1).
        page(params[:page]).per(50)
    end
end
