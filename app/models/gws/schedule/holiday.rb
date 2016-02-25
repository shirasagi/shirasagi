class Gws::Schedule::Holiday
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Planable
  include Gws::SitePermission

  set_permission_name "gws_schedule_holidays", :edit

  def allday?
    true
  end

  def calendar_format
     { className: 'fc-holiday', title: "  #{name}",
       start: start_at, end: (end_at + 1.day).to_date, allDay: allday?, editable: false }
  end
end
