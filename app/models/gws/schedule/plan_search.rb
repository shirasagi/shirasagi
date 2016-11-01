class Gws::Schedule::PlanSearch
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site

  field :start_on, type: Date, default: ->{ Time.zone.today }
  field :end_on, type: Date, default: ->{ Time.zone.today + 20.days }
  field :wdays, type: Array, default: []
  field :min_hour, type: Integer, default: 8
  field :max_hour, type: Integer, default: 22

  embeds_ids :members, class_name: "Gws::User"
  embeds_ids :facilities, class_name: "Gws::Facility::Item"

  permit_params :start_on, :end_on, :min_hour, :max_hour
  permit_params wdays: [], member_ids: [], facility_ids: []

  before_validation :validate_wdays
  before_validation :validate_hours

  def hours
    (min_hour..(max_hour - 1)).to_a
  end

  def search
    @condition = []
    set_members_condition
    set_facilities_condition
    return [] if @condition.blank?

    plans = Gws::Schedule::Plan.site(@cur_site).
      between_dates(start_on, end_on + 1.day).
      and('$or' => @condition)

    free_times(plans)
  end

  def free_times(plans)
    plan_times = {}
    plans.each do |plan|
      time = Time.zone.parse plan.start_at.strftime("%Y-%m-%d %H:00:00")
      fids = facility_ids & plan.facility_ids

      while time < plan.end_at
        hour = time.hour
        #plan_times[time.strftime("%Y-%m-%d #{hour}")] = fids if hour >= min_hour && hour <= max_hour
        if hour >= min_hour && hour <= max_hour
          key = time.strftime("%Y-%m-%d #{hour}")
          plan_times[key] ||= []
          plan_times[key] += fids
          plan_times[key].uniq!
        end
        time += 1.hour
      end
    end

    free_times = []
    (start_on..end_on).each do |date|
      next if wdays.present? && !wdays.include?(date.wday)

      ymd = date.strftime('%Y-%m-%d')
      hours = []
      f_hours = {}
      self.hours.each do |i|
        if @facilities.blank?
          hours << i unless plan_times.key?("#{ymd} #{i}")
          next
        end

        @facilities.each do |facility|
          next if plan_times.key?("#{ymd} #{i}") && plan_times["#{ymd} #{i}"].index(facility.id)

          f_hours[facility.id] ||= []
          f_hours[facility.id] << i
        end
      end
      free_times << [date, [hours, f_hours.presence]] if hours.present? || f_hours.present?
    end

    return free_times
  end

  private
    def validate_wdays
      self.wdays = wdays.reject(&:blank?).map(&:to_i)
    end

    def validate_hours
      self.max_hour = min_hour + 1 if min_hour > max_hour
    end

    def set_members_condition
      return if member_ids.blank?

      members = Gws::User.site(@cur_site).
        active.
        any_in(id: member_ids)

      return if members.blank?
      @condition << { member_ids: { '$in' => members.map(&:id) } }
    end

    def set_facilities_condition
      return if facility_ids.blank?

      @facilities = Gws::Facility::Item.site(@cur_site).
        readable(@cur_user, @cur_site).
        active.
        any_in(id: facility_ids)

      return if facilities.blank?
      @condition << { facility_ids: { '$in' => facilities.map(&:id) } }
    end
end
