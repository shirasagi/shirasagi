class Gws::Affair2::TimeCardForms::EnterController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair2::TimeCardForms::TimeEdit

  helper Gws::Affair2::TimeCardFormsHelper

  before_action :set_time_card
  before_action :set_record
  before_action :set_item
  before_action :set_ref, only: [:update, :punch]

  private

  def set_time_card
    @time_card = Gws::Affair2::Attendance::TimeCard.find(params[:id])
  end

  def set_record
    date = @time_card.date.change(day: params[:day].to_i)
    @record = @time_card.records.find_by(date: date)
  end

  def set_item
    @item = @model.new(@record, field_name)
  end

  def set_ref
    @ref = params[:ref]
    raise "404" if @ref.blank?
    raise "404" if !trusted_url?(@ref)
  end

  def location
    @ref
  end

  def field_name
    "enter"
  end

  public

  def index
    if !@item.hour
      @item.hour = view_context.default_hour
      @item.minute = view_context.default_minute
    end
  end

  def update
    @item.attributes = params.require(:item).permit(:hour, :minute, :reason)
    if @item.save
      @time_card.histories.create(
        date: @record.date, field_name: field_name, action: "modify",
        time: Time.zone.now, reason: @item.reason)
      flash[:notice] = I18n.t("ss.notice.saved")
      render :update
    else
      render :index
    end
  end

  def punch
    #raise '403' if !@model.allowed?(:use, @cur_user, site: @cur_site)

    if @time_card.locked?
      redirect_to(location, { notice: t('gws/attendance.already_locked') })
      return
    end

    @time_card.punch(field_name, @record.date)
    redirect_to location, notice: t('gws/attendance.notice.punched')
  end
end
