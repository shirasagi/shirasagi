class Gws::Affair2::Attendance::TimeCard
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::Reference::User
  include Gws::Affair2::TimeCardAggregation
  include Gws::Affair2::TimeCardPermission

  seqid :id
  set_permission_name "gws_affair2_attendance_time_cards"

  field :name, type: String
  field :date, type: DateTime
  field :lock_state, type: String
  field :regular_state, type: String, default: "close"

  embeds_many :histories, class_name: 'Gws::Affair2::Attendance::History'
  embeds_many :records, class_name: 'Gws::Affair2::Attendance::Record'
  belongs_to :attendance_setting, class_name: "Gws::Affair2::AttendanceSetting"

  before_validation :normalize_date
  before_validation :set_name
  after_create :create_records
  after_save :update_regular_state

  validates :lock_state, inclusion: { in: %w(locked unlocked processing), allow_blank: true }
  validates :attendance_setting_id, presence: true

  def view_year_month
    "#{date.year}#{format('%02d', date.month)}"
  end

  def punch(field_name, date, punch_at = Time.zone.now)
    raise "unable to punch: #{field_name}" if !Gws::Affair2::Attendance::Record.punchable_field_names.include?(field_name)

    record = self.records.find_by(date: date)
    if record.send(field_name).present?
      errors.add :base, :already_punched
      return false
    end

    record.send("#{field_name}=", punch_at)
    self.histories.create(date: date, field_name: field_name, action: 'set', time: punch_at)

    # change gws user's presence
    @cur_user.presence_punch((@cur_site || site), field_name) if @cur_user
    record.save
  end

  def locked?
    lock_state == 'locked'
  end

  def processing?
    lock_state == 'processing'
  end

  def unlocked?
    !locked? && !processing?
  end

  def regular_open?
    regular_state == "open"
  end

  def update_regular_state
    state = records.all?(&:regular_open?) ? "open" : "close"
    self.set(regular_state: state)
  end

  private

  def normalize_date
    return if self.date.blank?

    if self.date.day != 1
      self.date = date.beginning_of_month
    end
  end

  def set_name
    self.name ||= begin
      month = I18n.l(date.to_date, format: :attendance_year_month)
      I18n.t('gws/attendance.formats.time_card_name', month: month)
    end
  end

  def create_records
    duty_setting = attendance_setting.duty_setting
    (date..date.end_of_month).each do |date|
      record = self.records.find_or_initialize_by(date: date)
      if duty_setting
        record.regular_holiday = duty_setting.regular_holiday(date)
        record.regular_start = duty_setting.start_time(date)
        record.regular_close = duty_setting.close_time(date)
        record.regular_break_minutes = duty_setting.break_minutes(date)
        record.regular_work_minutes = duty_setting.work_minutes(date)
      end
      record.save!
    end
    update_regular_state
  end

  class << self
    def search(params = {})
      all.search_name(params).search_keyword(params).search_group(params)
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?

      all.search_text(params[:name])
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name)
    end

    def search_group(params)
      return all if params.blank? || params[:group].blank?

      group_ids = Gws::Group.active.in_group(params[:group]).pluck(:id)
      user_ids = Gws::User.active.in(group_ids: group_ids).pluck(:id)
      all.in(user_id: user_ids)
    end

    def in_groups(groups)
      group_ids = []
      groups.each do |group|
        group_ids += Gws::Group.in_group(group).pluck(:id)
      end
      group_ids.uniq!

      users = Gws::User.in(group_ids: group_ids).active
      user_ids = users.pluck(:id)

      all.in(user_id: user_ids)
    end

    def and_unlocked
      all.and('$or' => [{ lock_state: 'unlocked' }, { :lock_state.exists => false }])
    end

    def and_locked
      all.where(lock_state: 'locked')
    end

    def lock_all(site)
      items = self.all
      items.update_all({ "$set" => { lock_state: "processing" } })
      Gws::Affair2::TimeCardLockJob.bind(site_id: site).perform_later(items.pluck(:id))
      true
    end

    def unlock_all(site)
      items = self.all
      items.update_all({ "$set" => { lock_state: "processing" } })
      Gws::Affair2::TimeCardUnlockJob.bind(site_id: site).perform_later(items.pluck(:id))
      true
    end

    def enum_csv(site, params)
      raise "not implemented"
    end
  end
end
