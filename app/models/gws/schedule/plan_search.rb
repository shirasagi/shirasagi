class Gws::Schedule::PlanSearch
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site

  field :start_on, type: Date, default: ->{ Time.zone.today }
  field :end_on, type: Date, default: ->{ Time.zone.today + 30.days }
  field :wdays, type: Array, default: []
  field :min_hour, type: Integer, default: 8
  field :max_hour, type: Integer, default: 21

  embeds_ids :members, class_name: "Gws::User"
  embeds_ids :facilities, class_name: "Gws::Facility::Item"

  permit_params :start_on, :end_on
  permit_params wdays: [], member_ids: [], facility_ids: []

  before_validation :validate_wdays

  def hours
    (min_hour..max_hour).to_a
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
      while time < plan.end_at
        hour = time.hour
        plan_times[time.strftime("%Y-%m-%d #{hour}")] = nil if hour >= min_hour && hour <= max_hour
        time += 1.hour
      end
    end

    free_times = []
    (start_on..end_on).each do |date|
      next if wdays.present? && !wdays.include?(date.wday)

      ymd = date.strftime('%Y-%m-%d')
      hours = []
      (min_hour..max_hour).each { |i| hours << i unless plan_times.key?("#{ymd} #{i}") }
      free_times << [date, hours] # if hours.present?
    end

    return free_times
  end

  private
    def validate_wdays
      self.wdays = wdays.reject(&:blank?).map(&:to_i)
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
      return facility_ids.blank?

      facilities = Gws::Facility::Item.site(@cur_site).
        readable(@cur_user, @cur_site).
        active.
        any_in(id: facility_ids)

      return if facilities.blank?
      @condition << { facility_ids: { '$in' => facilities.map(&:id) } }
    end
end
