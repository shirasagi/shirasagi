class Gws::Schedule::Plan
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
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

  validates :start_at, presence: true, if: -> { !repeat? }
  validates :end_at, presence: true, if: -> { !repeat? }
  validate :validate_file_size

  def custom_group_member?(user)
    custom_groups.where(member_ids: user.id).exists?
  end

  def category_options
    @category_options ||= Gws::Schedule::Category.site(@cur_site || site).
      readable(@cur_user || user, site).
      map { |c| [c.name, c.id] }
  end

  def reminder_user_ids
    member_ids
  end

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    #data[:readable] = allowed?(:read, user, site: site)
    data[:readable] = readable?(user)
    data[:editable] = allowed?(:edit, user, site: site)

    data[:title] = I18n.t("gws/schedule.private_plan")
    data[:title] = name if data[:readable]

    if allday? || start_at.to_date != end_at.to_date
      data[:className] = 'fc-event-range'
      data[:backgroundColor] = category.color if category
      data[:textColor] = category.text_color if category
    else
      data[:className] = 'fc-event-point'
      data[:textColor] = category.color if category
    end

    if allday?
      data[:start] = start_at.to_date
      data[:end] = (end_at + 1.day).to_date
      data[:className] += " fc-event-allday"
    end

    if repeat_plan_id
      data[:title]      = " #{data[:title]}"
      data[:className] += " fc-event-repeat"
    end
    data
  end

  def calendar_facility_format(user, site)
    data = calendar_format(user, site)
    data[:className] = 'fc-event-range'
    data[:backgroundColor] = category.color if category
    data[:textColor] = category.text_color if category
    data
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
end
