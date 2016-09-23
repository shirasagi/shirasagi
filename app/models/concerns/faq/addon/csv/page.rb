require "csv"

module Faq::Addon::Csv
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    module ClassMethods
      def csv_headers
        %w(
            filename name index_name layout order
            keywords description summary_html
            question html
            categories
            event_name event_dates
            related_pages
            parent_crumb
            contact_state contact_group contact_charge contact_tel contact_fax contact_email
            released release_date close_date
            groups permission_level
            state
          )
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
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
            line << item.question
            line << item.html

            # category
            line << item.categories.pluck(:name).join("\n")

            # event
            line << item.event_name
            line << item.event_dates

            # related pages
            line << item.related_pages.pluck(:filename).join("\n")

            # crumb
            line << item.parent_crumb_urls

            # contact
            line << item.label(:contact_state)
            line << item.contact_group.try(:name)
            line << item.contact_charge
            line << item.contact_tel
            line << item.contact_fax
            line << item.contact_email

            # released
            line << item.released.try(:strftime, "%Y/%m/%d %H:%M")
            line << item.release_date.try(:strftime, "%Y/%m/%d %H:%M")
            line << item.close_date.try(:strftime, "%Y/%m/%d %H:%M")

            # groups
            line << item.groups.pluck(:name).join("\n")
            line << item.permission_level

            # state
            line << item.label(:state)

            data << line
          end
        end
      end
    end
  end
end
