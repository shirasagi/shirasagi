class Gws::Affair2::Overtime::RecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter

  model Gws::Affair2::Overtime::Record

  layout "ss/item_frame"

  before_action :set_frame_id
  before_action :set_overtime_file
  before_action :set_item

  after_action :send_record_entered, only: [:update]
  after_action :send_record_confirmed, only: [:confirmed]

  def set_frame_id
    @frame_id = "overtime-records"
  end

  def set_overtime_file
    @overtime_file = Gws::Affair2::Overtime::File.site(@cur_site).find(params[:file_id].to_i)
  end

  def set_item
    @item = @overtime_file.record || @model.new
    @item.attributes = fix_params
    @item.file = @overtime_file
    @item.date = @overtime_file.date
    @item.load_in_accessor
  end

  def fix_params
    {
      cur_user: @cur_user,
      cur_site: @cur_site,
      file: @overtime_file,
      date: @overtime_file.date
    }
  end

  def send_record_entered
    return if @first_entered.nil?
    return if @first_entered.errors.present?

    user_ids = @overtime_file.workflow_approvers.map { |item| item[:user_id] }.select(&:present?)
    to_users = Gws::User.in(id: user_ids).to_a
    to_users.reject! { |user| user.id == @cur_user.id }
    to_users.select! { |user| user.use_notice?(@overtime_file) }

    notifier = Gws::Affair2::Notifier.new(@overtime_file)
    notifier.deliver_record_entered(to_users)
  end

  def send_record_confirmed
    return if @first_confirmed.nil?
    return if @first_confirmed.errors.present?

    to_users = [@overtime_file.user]
    to_users.reject! { |user| user.id == @cur_user.id }
    to_users.select! { |user| user.use_notice?(@overtime_file) }

    notifier = Gws::Affair2::Notifier.new(@overtime_file)
    notifier.deliver_record_confirmed(to_users)
  end

  def show
  end

  def edit
  end

  def update
    @item.attributes = get_params

    if !@item.entered?
      @item.entered_at = Time.zone.now
      @first_entered = @item
    end
    render_update @item.save, notice: t("ss.notice.saved")
  end

  def confirmed
    if !@item.confirmed?
      @item.confirmed_at = Time.zone.now
      @first_confirmed = @item
    end
    render_update @item.update, notice: t("ss.notice.saved")
  end
end
