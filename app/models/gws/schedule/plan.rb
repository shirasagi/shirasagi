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

  # 公開範囲
  field :target, type: String, default: "all"

  # 種別
  belongs_to :category, class_name: 'Gws::Schedule::Category'

  permit_params :target

  validates :start_at, presence: true, if: -> { !repeat? }
  validates :end_at, presence: true, if: -> { !repeat? }

  def target_options
    keys = %w(all group member)
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
end
