class Event::Apis::RepeatDatesController < ApplicationController
  include Cms::ApiFilter

  def index
    #
  end

  def create
    @repeat_start = params[:repeat_start]
    @repeat_end = params[:repeat_end]
    @days = params[:days]
    @wdays = params[:wdays]
    @errors = []

    begin
      @repeat_start = Date.parse(@repeat_start)
    rescue
      @errors << I18n.t("event.apis.repeat_dates.start_blank")
    end

    begin
      @repeat_end = Date.parse(@repeat_end)
    rescue
      @errors << I18n.t("event.apis.repeat_dates.end_blank")
    end

    if @errors.present?
      render json: @errors, status: 422
      return
    end

    dates = []
    range = []
    repeat_dates.each do |d|
      if range.present? && range.last.tomorrow != d
        dates << range
        range = []
      end
      range << d
    end
    dates << range if range.present?
    @dates = dates.map do |range|
      [range.first.strftime("%Y/%m/%d"), range.last.strftime("%Y/%m/%d")]
    end

    @errors << I18n.t("event.apis.repeat_dates.not_found_dates") if @dates.blank?
    if @errors.present?
      render json: @errors, status: 422
      return
    end
  end

  private
    def repeat_dates
      dates = []
      @repeat_start.step(@repeat_end, 1) do |d|
        dates << d if @days.include?(d.day.to_s)
        dates << d if @wdays.include?(d.wday.to_s)
      end
      dates
    end
end
