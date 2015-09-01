module Gws::Schedule::PlanFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path "app/views/gws/schedule/plans"
    navi_view "gws/schedule/main/navi"
    helper Gws::Schedule::PlanHelper
    model Gws::Schedule::Plan
  end

  private
    def set_crumbs
      @crumbs << [:"modules.gws_schedule", gws_schedule_calendars_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      # TODO: term condition
      # params[:start]
      # params[:end]

      item = Gws::Schedule::Plan.site(@cur_site).user(@cur_user)
      item = item.any_of name: /.*#{params[:keyword]}.*/ if params[:keyword].present?

      @items = item.order_by(start_at: -1)
    end
end
