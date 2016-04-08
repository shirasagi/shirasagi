class Gws::Share::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::FileFilter

  model Gws::Share::File

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

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
