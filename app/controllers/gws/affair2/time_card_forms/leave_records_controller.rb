class Gws::Affair2::TimeCardForms::LeaveRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair2::TimeCardForms::LeaveRecords

  helper Gws::Affair2::TimeCardFormsHelper

  before_action :set_time_card
  before_action :set_item

  private

  def set_time_card
    @time_card = Gws::Affair2::Attendance::TimeCard.find(params[:id])
  end

  def set_item
    date = @time_card.date.change(day: params[:day].to_i)
    user = @time_card.user
    records = Gws::Affair2::Leave::Record.site(@cur_site).user(user).where(date: date).to_a

    @item = @model.new
    @item.site = @cur_site
    @item.user = @time_card.user
    @item.date = date
    @item.records = records
  end

  public

  def index
  end
end
