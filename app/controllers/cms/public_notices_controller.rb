class Cms::PublicNoticesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Notice

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.notice", action: :index]
    end

  public
    def index
      @items = @model.site(@cur_site).and_public.
        target_to(@cur_user).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @model.site(@cur_site).and_public.target_to(@cur_user).find(@item.id)
      render
    end
end
