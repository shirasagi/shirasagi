class Gws::Schedule::Holiday
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Colorize
  include Gws::Schedule::Planable
  include Gws::Addon::Schedule::Repeat
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name "gws_schedule_holidays", :edit

  field :color, type: String, default: "#99dd66"

  permit_params :color

  validates :color, presence: true

  def allday?
    true
  end

  def calendar_format
    {
      className: 'fc-holiday',
      title: "  #{name}",
      start: start_at,
      end: (end_at + 1.day).to_date,
      allDay: allday?,
      backgroundColor: color,
      textColor: text_color,
      editable: false
    }
  end
end
