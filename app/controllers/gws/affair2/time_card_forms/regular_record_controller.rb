class Gws::Affair2::TimeCardForms::RegularRecordController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair2::TimeCardForms::RegularRecords

  helper Gws::Affair2::TimeCardFormsHelper

  before_action :set_time_card
  before_action :set_item
  before_action :set_ref, only: [:update]

  private

  def set_time_card
    @time_card = Gws::Affair2::Attendance::TimeCard.find(params[:id])
  end

  def set_item
    @item = @model.new(@time_card)
  end

  def set_ref
    @ref = params[:ref]
    raise "404" if @ref.blank?
    raise "404" if !trusted_url?(@ref)
  end

  public

  def index
  end

  def update
    @item.attributes = params.require(:item).permit(:in_file)

    if @item.import
      @time_card.update_regular_state
      flash[:notice] = I18n.t("ss.notice.saved")
      render :update
    else
      render :index
    end
  end

  def download
    options = {}
    send_enum @item.enum_csv(options), filename: "attendance_settings_#{Time.zone.now.to_i}.csv"
  end
end
