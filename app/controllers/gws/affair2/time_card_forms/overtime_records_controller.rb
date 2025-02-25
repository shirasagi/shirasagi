class Gws::Affair2::TimeCardForms::OvertimeRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Affair2::TimeCardForms::OvertimeRecords

  helper Gws::Affair2::TimeCardFormsHelper

  before_action :set_time_card
  before_action :set_item
  before_action :set_ref, only: [:update]

  after_action :send_record_entered, only: [:update]

  private

  def set_time_card
    @time_card = Gws::Affair2::Attendance::TimeCard.find(params[:id])
  end

  def set_item
    date = @time_card.date.change(day: params[:day].to_i)
    user = @time_card.user
    records = Gws::Affair2::Overtime::Record.site(@cur_site).user(user).where(date: date).to_a

    @item = @model.new
    @item.site = @cur_site
    @item.user = @time_card.user
    @item.date = date
    @item.records = records
  end

  def set_ref
    @ref = params[:ref]
    raise "404" if @ref.blank?
    raise "404" if !trusted_url?(@ref)
  end

  def send_record_entered
    return if @item.errors.present?
    return if @item.first_entered_records.blank?

    @item.first_entered_records.each do |record|
      file = record.file
      user_ids = file.workflow_approvers.map { |item| item[:user_id] }.select(&:present?)
      to_users = Gws::User.in(id: user_ids).to_a
      to_users.select! { |user| user.id != @cur_user.id }
      to_users.select! { |user| user.use_notice?(file) }

      notifier = Gws::Affair2::Notifier.new(file)
      notifier.deliver_record_entered(to_users)
    end
  end

  public

  def index
  end

  def update
    @item.attributes = params.require(:item).permit(in_records: {})
    if @item.save
      flash[:notice] = I18n.t("ss.notice.saved")
      render :update
    else
      render :index
    end
  end
end
