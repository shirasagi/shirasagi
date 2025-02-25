class Gws::Affair2::Leave::Achieve
  include ActiveModel::Model
  include SS::Permission
  include Gws::Addon::Affair2::Achieve::PaidLeave
  include Gws::Addon::Affair2::Achieve::OtherLeave
  include Gws::Affair2::SubGroupPermission

  set_permission_name "gws_affair2_leave_achieves"

  attr_reader :site, :user, :group, :month
  attr_reader :start_date, :close_date
  attr_reader :organization_uid
  attr_reader :attendance_setting, :duty_setting, :paid_leave_setting
  attr_reader :paid_leave_files, :other_leave_files

  validate :validate_attendance_setting

  def initialize(site, user, group, month)
    @site = site
    @user = user
    @group = group
    @month = month

    @start_date = Time.zone.local(@month.year, 1, 1)
    @close_date = @month.end_of_month
  end

  def load
    set_attendance_setting
    return if invalid?

    @organization_uid = @attendance_setting.organization_uid

    @paid_leave_setting.with_start = start_date
    @paid_leave_setting.with_close = close_date

    @leave_files = Gws::Affair2::Leave::File.site(site).user(user).and([
      start_at: { "$gte" => start_date },
      close_at: { "$lte" => close_date },
      workflow_state: "approve"
    ]).order_by(start_at: 1).to_a

    @paid_leave_files, @other_leave_files = @leave_files.partition { |item| item.paid_leave? }
  end

  def carryover_minutes_label
    return if paid_leave_setting.nil?
    paid_leave_setting.carryover_minutes_label(duty_setting.day_leave_minutes)
  end

  def additional_minutes_label
    return if paid_leave_setting.nil?
    paid_leave_setting.additional_minutes_label(duty_setting.day_leave_minutes)
  end

  def effective_minutes_label
    return if paid_leave_setting.nil?
    paid_leave_setting.effective_minutes_label(duty_setting.day_leave_minutes)
  end

  def used_minutes_label
    return if paid_leave_setting.nil?
    paid_leave_setting.used_minutes_label(duty_setting.day_leave_minutes)
  end

  def remind_minutes_label
    return if paid_leave_setting.nil?
    paid_leave_setting.remind_minutes_label(duty_setting.day_leave_minutes)
  end

  def set_attendance_setting
    # 対象年の最新の出退勤設定を参照する
    @attendance_setting = Gws::Affair2::AttendanceSetting.site(@site).user(@user).
      and_between(start_date, close_date).first
    return if @attendance_setting.nil?

    @duty_setting = @attendance_setting.duty_setting
    @paid_leave_setting = @attendance_setting.paid_leave_settings.where(year: month.year).first
  end

  def validate_attendance_setting
    if @attendance_setting.nil?
      errors.add :base, "出退勤設定がありません。"
      return
    end
    if @duty_setting.nil?
      errors.add :base, "雇用区分設定がありません。"
      return
    end
    if @paid_leave_setting.nil?
      errors.add :base, "有給日数の設定がありません。"
      return
    end
  end

  ## addons

  def addons(addon_type = nil)
    if addon_type
      self.class.addons.select { |m| m.type == addon_type }
    else
      self.class.addons.select { |m| m.type.nil? }
    end
  end

  class << self
    def addon(path)
      include path.sub("/", "/addon/").camelize.constantize
    end

    def addons
      #return @addons if @addons
      @addons = lookup_addons.reverse.map { |m| m.addon_name }
    end

    def lookup_addons
      ancestors.select { |x| x.respond_to?(:addon_name) }
    end
  end
end
