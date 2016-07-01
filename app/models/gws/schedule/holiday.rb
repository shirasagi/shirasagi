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

  def readable?(user)
    true
  end

  def allday?
    true
  end

  def calendar_format(opts = {})
    data = {
      id: id.to_s,
      start: start_at,
      end: (end_at + 1.day).to_date,
      title: "  #{name}",
      className: 'fc-holiday',
      allDay: allday?,
      backgroundColor: color,
      textColor: text_color,
      editable: false,
      noPopup: true
    }
    return data unless opts[:editable]

    data.merge({
      editable: true,
      noPopup: false
    })
  end
end
