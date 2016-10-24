require "csv"

module Event::Addon::Csv
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    module ClassMethods
      def csv_headers
        %w(
            filename name index_name layout order
            keywords description summary_html
            html
            schedule venue content cost related_url contact
            categories
            event_name event_dates
            related_pages
            parent_crumb
            released release_date close_date
            groups permission_level
            state
          )
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            data << csv_line(item)
          end
        end
      end

      def csv_line(item)
        line = []

        # basic
        line << item.basename
        line << item.name
        line << item.index_name
        line << item.layout.try(:name)
        line << item.order

        # meta
        line << item.keywords
        line << item.description
        line << item.summary_html

        # body
        line << item.html

        # event body
        line << item.schedule
        line << item.venue
        line << item.content
        line << item.cost
        line << item.related_url
        line << item.contact

        # category
        line << item.categories.pluck(:name).join("\n")

        # event
        line << item.event_name
        line << item.event_dates

        # related pages
        line << item.related_pages.pluck(:filename).join("\n")

        # crumb
        line << item.parent_crumb_urls

        # released
        line << item.released.try(:strftime, "%Y/%m/%d %H:%M")
        line << item.release_date.try(:strftime, "%Y/%m/%d %H:%M")
        line << item.close_date.try(:strftime, "%Y/%m/%d %H:%M")

        # groups
        line << item.groups.pluck(:name).join("\n")
        line << item.permission_level

        # state
        line << item.label(:state)

        line
      end
    end
  end
end
