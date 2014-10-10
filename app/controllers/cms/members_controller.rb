class Cms::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Member

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.member", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
