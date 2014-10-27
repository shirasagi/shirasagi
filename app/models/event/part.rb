module Event::Part
  class Calendar
    include Cms::Part::Model

    default_scope ->{ where(route: "event/calendar") }
  end
end
