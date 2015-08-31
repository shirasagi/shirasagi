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

    def pre_params
      now = Time.zone.now
      min = now.min / 5 * 5
      start_at = Time.zone.local now.year, now.month, now.day, now.hour, min
      { start_at: start_at, end_at: start_at + 5.minutes }
    end

    def ajax_params
      if params[:end_at] == ''
        span = self.end_at - self.start_at
        start_at = params[:start_at]
        end_at = start_at + span
      else
        start_at = params[:start_at]
        end_at = params[:end_at]
      end

      { start_at: start_at, end_at: end_at }
    end

  public
    def index
      item = Gws::Schedule::Plan.site(@cur_site).user(@cur_user)
      item = item.any_of name: /.*#{params[:keyword]}.*/ if params[:keyword].present?

      @items = item.order_by(start_at: -1)
    end

    def create_x
      respond_to do |format|
        format.html { super }
        format.json { super }
        format.js do
          @item = @model.new get_params
          if @item.save
            render status: 200
          else
            render status: 403
          end
        end
      end
    end

    def update_x
      respond_to do |format|
        format.html { super }
        format.json { super }
        format.js do
          if @item.update ajax_params
            render status: 200
          else
            render status: 403
          end
        end
      end
    end
end
