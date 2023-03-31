module Rss::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^rss\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Rss::Addon::Import
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "rss/page") }

    after_save :purge_pages, if: ->{ @db_changes && @db_changes["rss_max_docs"] }

    private

    def purge_pages
      Rss::Page.limit_docs((@cur_site || site), self, rss_max_docs)
    end
  end

  class WeatherXml
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Rss::Addon::Import
    include Rss::Addon::AnpiMailSetting
    include Jmaxml::Addon::Filter
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "rss/weather_xml") }
    self.weather_xml = true
    self.default_rss_max_docs = 100

    after_save :purge_pages, if: ->{ @db_changes && @db_changes["rss_max_docs"] }

    def execute_weather_xml_filter(page, context)
      return if page.blank?
      return if filters.blank?

      context[:site] ||= site
      context[:user] ||= user
      context[:node] ||= self
      filters.and_enabled.each do |filter|
        begin
          filter.execute(page, context)
        rescue => e
          Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        end
      end
    end

    private

    def purge_pages
      Rss::Page.limit_docs((@cur_site || site), self, rss_max_docs)
    end
  end
end
