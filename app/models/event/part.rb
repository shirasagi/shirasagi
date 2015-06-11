module Event::Part
  class Calendar
    include Cms::Model::Part

    default_scope ->{ where(route: "event/calendar") }
  end
end
