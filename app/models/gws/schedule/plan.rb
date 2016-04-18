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
  include Gws::Addon::Schedule::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include ActiveSupport::NumberHelper

  permission_include_custom_group

  # 公開範囲
  field :target, type: String, default: "all"

  # 種別
  belongs_to :category, class_name: 'Gws::Schedule::Category'

  permit_params :target

  validates :start_at, presence: true, if: -> { !repeat? }
  validates :end_at, presence: true, if: -> { !repeat? }
  validate :validate_file_size

  def target_options
    keys = %w(all group member custom_group)
    keys.map { |key| [I18n.t("gws.options.target.#{key}"), key] }
  end

  def member?(user)
    member_ids.include?(user.id)
  end

  def targeted?(user)
    if target == "group"
      return group_ids.any? { |m| user.group_ids.include?(m) }
    elsif target == "member"
      return member?(user)
    elsif target == "custom_group"
      return Gws::CustomGroup.site(site || cur_site).where(:id.in => custom_group_ids).where(member_ids: user.id).exists?
    else
      true
    end
  end

  def category_options
    @category_options ||= Gws::Schedule::Category.site(@cur_site || site).
      target_to(@cur_user || user).
      map { |c| [c.name, c.id] }
  end

  def reminder_user_ids
    member_ids
  end

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    data[:readable] = allowed?(:read, user, site: site)
    data[:editable] = allowed?(:edit, user, site: site)

    data[:title] = I18n.t("gws/schedule.private_plan")
    data[:title] = ERB::Util.h(name) if data[:readable]

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
    if action == :read
      super || targeted?(user) || member?(user)
    elsif action =~ /edit|delete/
      super || member?(user)
    else
      super
    end
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
