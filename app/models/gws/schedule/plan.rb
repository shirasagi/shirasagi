class Gws::Schedule::Plan
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
  include Gws::Schedule::CalendarFormat
  include Gws::Addon::Reminder
  include Gws::Addon::Schedule::Repeat
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include ActiveSupport::NumberHelper

  member_include_custom_groups
  permission_include_custom_groups
  readable_setting_include_custom_groups

  # 種別
  belongs_to :category, class_name: 'Gws::Schedule::Category'

  validate :validate_file_size

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def category_options
    @category_options ||= Gws::Schedule::Category.site(@cur_site || site).
      readable(@cur_user || user, @cur_site || site).
      to_options
  end

  def reminder_user_ids
    member_ids
  end

  def allowed?(action, user, opts = {})
    return true if super
    member?(user) || custom_group_member?(user) if action =~ /edit|delete/
  end

  private
    def validate_file_size
      limit = cur_site.schedule_max_file_size || 0
      return if limit <= 0

      size = files.compact.map(&:size).max || 0
      if size > limit
        errors.add(
          :base,
          :file_size_exceeds_limit,
          size: number_to_human_size(size),
          limit: number_to_human_size(limit))
      end
    end

  class << self
    def free_times(sdate, edate, min_hour, max_hour)
      hours = (min_hour..max_hour).to_a

      plan_times = {}
      self.each do |plan|
        time = Time.zone.parse plan.start_at.strftime("%Y-%m-%d %H:00:00")
        while time < plan.end_at
          hour = time.hour
          plan_times[time.strftime("%Y-%m-%d #{hour}")] = nil if hour >= min_hour && hour <= max_hour
          time += 1.hour
        end
      end

      free_times = []
      (sdate..(edate - 1.day)).each do |date|
        ymd = date.strftime('%Y-%m-%d')
        hours = []
        (min_hour..max_hour).each { |i| hours << i unless plan_times.key?("#{ymd} #{i}") }
        free_times << [date, hours] # if hours.present?
      end

      return free_times
    end
  end
end
