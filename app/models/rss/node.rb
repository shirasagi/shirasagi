module Rss::Node
  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Release
    include Cms::Addon::Meta
    include Rss::Addon::Import
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "rss/page") }

    after_save :purge_pages, if: ->{ @db_changes && @db_changes["rss_max_docs"] }

    private
      def purge_pages
        Rss::Page.limit_docs(@cur_site, self, rss_max_docs)
      end
  end
end
