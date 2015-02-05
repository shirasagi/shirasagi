class Cms::Workflow::RoutesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Workflow::Route

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"workflow.name", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless @model.site(@cur_site).include?(@item)
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
