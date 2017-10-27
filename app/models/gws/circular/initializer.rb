module Gws::Circular
  class Initializer
    Gws::Role.permission :read_other_gws_circular_topics
    Gws::Role.permission :read_private_gws_circular_topics
    Gws::Role.permission :edit_other_gws_circular_topics
    Gws::Role.permission :edit_private_gws_circular_topics
    Gws::Role.permission :delete_other_gws_circular_topics
    Gws::Role.permission :delete_private_gws_circular_topics
  end
end
