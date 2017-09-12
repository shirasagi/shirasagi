module Gws::Monitor
  class Initializer
    Gws::Role.permission :read_other_gws_monitor_topics
    Gws::Role.permission :read_private_gws_monitor_topics

    Gws::Role.permission :edit_other_gws_monitor_topics
    Gws::Role.permission :edit_private_gws_monitor_topics

    Gws::Role.permission :delete_other_gws_monitor_topics
    Gws::Role.permission :delete_private_gws_monitor_topics
  end
end
