class Gws::RolesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Role

  prepend_view_path "app/views/ss/roles"

  private
    def set_crumbs
      @crumbs << [:"cms.role", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
