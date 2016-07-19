class Member::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Member::Group

  # navi_view "cms/main/conf_navi"
  navi_view "member/groups/navi"

  private
    def set_crumbs
      @crumbs << [:"member.group", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        search(params[:s]).
        allow(:edit, @cur_user, site: @cur_site).
        order_by(name: 1).
        page(params[:page]).per(50)
    end
end
