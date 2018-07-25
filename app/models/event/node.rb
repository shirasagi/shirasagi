module Event::Node
  class Base
    include Cms::Model::Node
    default_scope ->{ where(route: /^event\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Category::Addon::Setting
    include Event::Addon::CalendarList
    include Cms::Addon::TagSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
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

  class Ical
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Category::Addon::Setting
    include Event::Addon::CalendarList
    include Event::Addon::IcalImport
    include Cms::Addon::TagSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "event/page") }

    def condition_hash
      cond = super
      cond.merge "event_dates.0" => { "$exists" => true }
    end

    after_save :purge_pages, if: ->{ @db_changes && @db_changes["ical_max_docs"] }

    private

    def purge_pages
      Event::Page.limit_docs(@cur_site, self, ical_max_docs)
    end
  end
end
