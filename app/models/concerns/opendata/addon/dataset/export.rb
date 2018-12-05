require "csv"

module Opendata::Addon
  module Dataset::Export
    extend ActiveSupport::Concern
    extend SS::Addon

    module ClassMethods
      def csv_headers
        %w(
          id name text tags
          categories area_ids
          dataset_group_ids
          released
          contact_state contact_group contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
          related_pages
          groups
        )
      end

      def to_csv
        csv = CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            data << csv_line(item)
          end
        end
      end

      def csv_line(item)
        [
          # basic
          item.id,
          item.name,
          item.text,
          item.tags.join(","),

          # category area
          item.category_ids.join(","),
          item.area_ids.join(","),

          # dataset_group
          item.dataset_group_ids.join(","),

          # released
          item.released.try(:strftime, "%Y/%m/%d %H:%M"),

          # contact
          item.contact_state,
          item.contact_group_id,
          item.contact_charge,
          item.contact_tel,
          item.contact_fax,
          item.contact_email,
          item.contact_link_url,
          item.contact_link_name,

          # related pages
          item.related_pages.pluck(:filename).join(","),

          # groups
          item.group_ids.join(",")
        ]
      end
    end
  end
end
