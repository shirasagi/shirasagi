module Event::Node
  class Base
    include Cms::Model::Node
    default_scope ->{ where(route: /^event\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Category::Addon::Setting
    include Event::Addon::CalendarList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/page") }

    def condition_hash
      cond = super
      cond.merge "event_dates.0" => { "$exists" => true }
    end
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/search") }
  end
end
