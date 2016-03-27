class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
  include Gws::Addon::Schedule::Repeat
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Schedule::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::GroupPermission

  # 種別
  belongs_to :category, class_name: 'Gws::Schedule::Category'

  validates :start_at, presence: true, if: -> { !repeat? }
  validates :end_at, presence: true, if: -> { !repeat? }

  def category_options
    @category_options ||= Gws::Schedule::Category.site(@cur_site || site).
      target_to(@cur_user || user).
      map { |c| [c.name, c.id] }
  end

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format(user, site)
    data = { id: id.to_s, start: start_at, end: end_at, allDay: allday? }

    data[:readable] = allowed?(:read, user, site: site) || true #TODO:
    data[:editable] = allowed?(:edit, user, site: site)
    data[:deletable] = allowed?(:delete, user, site: site)

    if data[:readable]
      data[:title] = ERB::Util.h(name)
      data[:description] = ERB::Util.h(text.to_s.gsub(/^(.{40,}?).*$/m,'\1...'))
      data[:members] = t(:member_ids) + ": " + members.map(&:name).join(', ')
    else
      data[:title] = I18n.t("gws/schedule.private_plan")
    end

    if allday? || start_at.to_date != end_at.to_date
      data[:className] = 'fc-event-days'
      data[:backgroundColor] = category.color if category
      data[:textColor] = category.text_color if category
    else
      data[:className] = 'fc-event-one'
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
end
