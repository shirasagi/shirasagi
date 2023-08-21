class Event::Apis::EditExcludeDatesController < ApplicationController
  include Cms::ApiFilter

  def index
    @edit_params = Event::EditExcludeDatesParams.new(cur_site: @cur_site, cur_user: @cur_user, index: params[:index])
    @edit_params.attributes = params.require(:item).permit(event_recurrences: [
      :in_update_from_view, :in_start_on, :in_until_on, :in_all_day, :in_start_time, :in_end_time, :in_exclude_dates,
      in_by_days: []
    ])

    @item = @edit_params.cur_event_recurrence
    if @item.blank? || @item.start_date.blank?
      render json: [ I18n.t("event.apis.repeat_dates.start_blank") ], status: :bad_request
      return
    end

    @event_dates = @item.collect_event_dates(excludes: false)

    render
  end
end
