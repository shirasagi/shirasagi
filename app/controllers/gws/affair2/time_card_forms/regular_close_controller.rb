class Gws::Affair2::TimeCardForms::RegularCloseController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair2::TimeCardForms::TimeEdit

  helper Gws::Affair2::TimeCardFormsHelper

  before_action :set_time_card
  before_action :set_record
  before_action :set_item
  before_action :set_ref, only: [:update]

  private

  def set_time_card
    @time_card = Gws::Affair2::Attendance::TimeCard.find(params[:id])
  end

  def set_record
    date = @time_card.date.change(day: params[:day].to_i)
    @record = @time_card.records.find_by(date: date)
  end

  def set_item
    @item = @model.new(@record, field_name, required_reason: false)
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
    "regular_close"
  end

  public

  def index
  end

  def update
    @item.attributes = params.require(:item).permit(:hour, :minute)
    if @item.save
      @time_card.update_regular_state
      flash[:notice] = I18n.t("ss.notice.saved")
      render :update
    else
      render :index
    end
  end
end
