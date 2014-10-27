module Event
  class Initializer
    Cms::Node.plugin "event/page"
    Cms::Part.plugin "event/calendar"

    Cms::Role.permission :read_other_event_pages
    Cms::Role.permission :read_private_event_pages
    Cms::Role.permission :edit_other_event_pages
    Cms::Role.permission :edit_private_event_pages
    Cms::Role.permission :delete_other_event_pages
    Cms::Role.permission :delete_private_event_pages
  end
end
