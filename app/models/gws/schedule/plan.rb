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
    Gws::Schedule::Category.site(@cur_site || site).
      target_to(@cur_user || user).
      map { |c| [c.name, c.id] }
  end

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format
    data = { id: id, title: ERB::Util.h(name), start: start_at, end: end_at, allDay: allday? }

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
