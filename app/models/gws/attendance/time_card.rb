class Gws::Attendance::TimeCard
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::Reference::User
  include Gws::SitePermission

  field :name, type: String
  field :date, type: DateTime
  embeds_many :histories, class_name: 'Gws::Attendance::History'
  embeds_many :records, class_name: 'Gws::Attendance::Record'
  field :lock_state, type: String

  before_validation :normalize_date
  before_validation :set_name

  validates :lock_state, inclusion: { in: %w(locked unlocked), allow_blank: true }

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

    def lock_all
      criteria.each do |item|
        item.histories.create(date: item.date, field_name: '$all', action: 'lock')
        item.lock_state = 'locked'
        item.save!
      end
      true
    rescue
      false
    end

    def unlock_all
      criteria.each do |item|
        item.histories.create(date: item.date, field_name: '$all', action: 'unlock')
        item.lock_state = 'unlocked'
        item.save!
      end
      true
    rescue
      false
    end

    def enum_csv(site, params)
      Gws::Attendance::TimeCardEnumerator.new(site, all, params)
    end
  end

  def year_options
    cur_year = Time.zone.now.year

    ((cur_year - 5)..(cur_year + 5)).map do |year|
      ["#{year}年", year]
    end
  end

  def month_options
    (1..12).map do |month|
      ["#{month}月", month]
    end
  end

  def punch(field_name, now = Time.zone.now)
    raise "unable to punch: #{field_name}" if !Gws::Attendance::Record.punchable_field_names.include?(field_name)

    date = (@cur_site || site).calc_attendance_date(now)
    record = self.records.where(date: date).first
    if record.blank?
      record = self.records.create(date: date)
    end
    if record.send(field_name).present?
      errors.add :base, :already_punched
      return false
    end

    record.send("#{field_name}=", now)
    self.histories.create(date: date, field_name: field_name, action: 'set', time: now)
    record.save
  end

  def locked?
    lock_state == 'locked'
  end

  def unlocked?
    !locked?
  end

  def enum_csv(params)
    Gws::Attendance::TimeCardEnumerator.new(@cur_site || site, [ self ], params)
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
end
