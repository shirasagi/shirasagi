module Gws::Schedule::PlanFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/schedule/plans"
    menu_view "gws/schedule/main/menu"
    helper Gws::Schedule::PlanHelper
    model Gws::Schedule::Plan
  end

  private
    def set_crumbs
      @crumbs << [:"modules.gws/schedule", gws_schedule_plans_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def pre_params
      @skip_default_group = true
      { member_ids: [@cur_user.id], start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00') }
    end

  public
    def index
      render
    end

    def events
      @items = []
    end

    def popup
      set_item

      if @item.allowed?(:read, @cur_user, site: @cur_site)
        render file: "popup", layout: false
      else
        render file: "popup_hidden", layout: false
      end
    end
end
