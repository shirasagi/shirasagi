class Gws::Schedule::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  navi_view "gws/schedule/settings/navi"

  model Gws::Schedule::Holiday

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/schedule/group_setting", gws_schedule_setting_path]
      @crumbs << [:"mongoid.models.gws/schedule/group_setting/holiday", gws_schedule_holidays_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def pre_params
      {}
    end

    def redirection_view
      'month'
    end

  public
    def events
      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s])

      render json: @items.map { |m| m.calendar_format(editable: true) }.to_json
    end
end
