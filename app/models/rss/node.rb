module Rss::Node
  class Page
    include Cms::Node::Model
    include Rss::Addon::Import
    include Cms::Addon::PageList

    default_scope ->{ where(route: "rss/page") }

    after_save :purge_pages, if: ->{ @db_changes && @db_changes["rss_max_docs"] }

    private
      def purge_pages
        Rss::Page.limit_docs(@cur_site, self, rss_max_docs)
      end
  end
end
