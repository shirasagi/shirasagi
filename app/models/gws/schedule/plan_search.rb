class Gws::Schedule::PlanSearch
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site

  field :start_on, type: Date, default: ->{ Time.zone.today }
  field :end_on, type: Date, default: ->{ Time.zone.today + 20.days }
  field :wdays, type: Array, default: []
  field :min_hour, type: Integer, default: 8
  field :max_hour, type: Integer, default: 22
  field :repeat_type, type: String
  field :interval, type: Integer
  field :repeat_base, type: String, default: 'date'

  belongs_to :plan, class_name: "Gws::Schedule::Plan"

  embeds_ids :members, class_name: "Gws::User"
  embeds_ids :facilities, class_name: "Gws::Facility::Item"

  permit_params :start_on, :end_on, :min_hour, :max_hour, :plan_id
  permit_params wdays: [], member_ids: [], facility_ids: []
  permit_params :repeat_type, :interval, :repeat_base

  before_validation :validate_dates
  before_validation :validate_wdays
  before_validation :validate_hours

  validates :repeat_type, inclusion: { in: %w(daily weekly monthly yearly), allow_blank: true }
  validates :interval, presence: true, if: -> { repeat_type.present? }
  validates :interval, inclusion: { in: 1..10 }, if: -> { interval.present? }
  validates :repeat_base, inclusion: { in: %w(date wday), allow_blank: true }
  validates :repeat_base, presence: true, if: -> { repeat_type == 'monthly' }

  def hours
    (min_hour..(max_hour - 1)).to_a
  end

  def search
    @condition = []
    set_members_condition
    set_facilities_condition
    return [] if @condition.blank?

    plans = Gws::Schedule::Plan.site(@cur_site).
      ne(id: plan_id).
      without_deleted.
      between_dates(start_on, end_on + 1.day).
      and('$or' => @condition)

    free_times(plans)
  end

  def free_times(plans)
    plan_times = {}
    facility_times = {}
    plans.each do |plan|
      time = plan.start_at.change(min: 0)
      fids = facility_ids & plan.facility_ids

      while time < plan.end_at
        hour = time.hour
        #plan_times[time.strftime("%Y-%m-%d #{hour}")] = fids if hour >= min_hour && hour <= max_hour
        if hour >= min_hour && hour <= max_hour
          key = time.strftime("%Y-%m-%d #{hour}")
          plan_times[key] ||= []
          plan_times[key] += fids
          plan_times[key].uniq!

          facility_times[key] ||= {}
          fids.each do |fid|
            facility_times[key][fid] ||= []
            facility_times[key][fid] << plan
          end
        end
        time += 1.hour
      end
    end

    free_times = []
    enum_dates.each do |date|
      ymd = date.strftime('%Y-%m-%d')
      hours = []
      f_hours = {}
      p_hours = {}
      if @facilities.blank?
        self.hours.each do |i|
          hours << i unless plan_times.key?("#{ymd} #{i}")
        end
      else
        self.hours.each do |i|
          hours << i unless plan_times.key?("#{ymd} #{i}")
          datetime = (date + i.hours).to_datetime
          @facilities.each do |facility|
            if plan_times.key?("#{ymd} #{i}") && plan_times["#{ymd} #{i}"].index(facility.id)
              plans = facility_times["#{ymd} #{i}"][facility.id]

              p_hours[facility.id] ||= {}
              p_hours[facility.id][i] ||= []
              plans.each do |plan|
                p_hours[facility.id][i] << plan_attributes(plan)
              end
              next
            end

            next if facility.reservation_start_date.present? && datetime < facility.reservation_start_date
            next if facility.reservation_end_date.present? && datetime >= facility.reservation_end_date

            f_hours[facility.id] ||= []
            f_hours[facility.id] << i
          end
        end
      end
      free_times << [date, [hours, f_hours, p_hours]] #if hours.present? || f_hours.present?
    end

    return free_times
  end

  def link_params(params = {})
    params[:member_ids] = member_ids if member_ids.present?
    params[:facility_ids] = facility_ids if facility_ids.present?
    params
  end

  private

  def validate_dates
    return if start_on <= end_on

    self.start_on, self.end_on = [start_on, end_on].sort
  end

  def validate_wdays
    self.wdays = wdays.reject(&:blank?).map(&:to_i)
  end

  def validate_hours
    return if min_hour <= max_hour

    self.min_hour, self.max_hour = [min_hour, max_hour].sort
  end

  def set_members_condition
    return if member_ids.blank?

    members = Gws::User.site(@cur_site).
      active.
      any_in(id: member_ids)

    return if members.blank?
    @condition << { member_ids: { '$in' => members.map(&:id) } }

    set_member_custom_groups_condition
  end

  def set_member_custom_groups_condition
    groups = Gws::CustomGroup.site(@cur_site).
      any_in(member_ids: member_ids)

    return if groups.blank?
    @condition << { member_custom_group_ids: { '$in' => groups.map(&:id) } }
  end

  def set_facilities_condition
    return if facility_ids.blank?

    @facilities = Gws::Facility::Item.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      active.
      any_in(id: facility_ids)

    return if facilities.blank?
    @condition << { facility_ids: { '$in' => facilities.map(&:id) } }
  end

  def enum_dates
    Gws::Schedule::DateEnumerator.new(
      repeat_type: repeat_type.presence || (wdays.present? ? 'weekly' : 'daily'),
      repeat_start: start_on, repeat_end: end_on,
      interval: interval || 1,
      wdays: wdays, repeat_base: repeat_base
    )
  end

  def plan_attributes(plan)
    attr = { id: plan.id.to_s }
    if plan.user
      attr[:user_long_name] = plan.user.long_name

      section_name = plan.section_name
      attr[:user_section_name] = section_name if section_name
    end
    attr
  end
end
