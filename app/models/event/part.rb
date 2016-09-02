module Event::Part
  class Calendar
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Part

    default_scope ->{ where(route: "event/calendar") }
  end
end
