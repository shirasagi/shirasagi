module Event
  class Initializer
    Cms::Node.plugin "event/page"
    Cms::Node.plugin "event/search"
    Cms::Part.plugin "event/calendar"
    Cms::Part.plugin "event/search"

    Cms::Role.permission :read_other_event_pages
    Cms::Role.permission :read_private_event_pages
    Cms::Role.permission :edit_other_event_pages
    Cms::Role.permission :edit_private_event_pages
    Cms::Role.permission :delete_other_event_pages
    Cms::Role.permission :delete_private_event_pages
    Cms::Role.permission :release_other_event_pages
    Cms::Role.permission :release_private_event_pages
    Cms::Role.permission :approve_other_event_pages
    Cms::Role.permission :approve_private_event_pages
    Cms::Role.permission :reroute_other_event_pages
    Cms::Role.permission :reroute_private_event_pages
    Cms::Role.permission :revoke_other_event_pages
    Cms::Role.permission :revoke_private_event_pages
    Cms::Role.permission :move_private_event_pages
    Cms::Role.permission :move_other_event_pages
    Cms::Role.permission :import_private_event_pages
    Cms::Role.permission :import_other_event_pages
  end
end
