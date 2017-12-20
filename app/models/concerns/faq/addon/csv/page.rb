require "csv"

module Faq::Addon::Csv
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    def category_name_tree
      id_list = categories.pluck(:id)

      ct_list = []
      id_list.each do |id|
        name_list = []
        filename_str = []
        filename_array = Cms::Node.where(_id: id).map(&:filename).first.split(/\//)
        filename_array.each do |filename|
          filename_str << filename
          name_list << Cms::Node.where(filename: filename_str.join("/")).map(&:name).first
        end
        ct_list << name_list.join("/")
      end
      ct_list
    end

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
            contact_state contact_group contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
            released release_date close_date
            groups permission_level
            state
          )
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each { |item| data << csv_line(item) }
        end
      end

      def csv_line(item)
        [
          # basic
          item.basename,
          item.name,
          item.index_name,
          item.layout.try(:name),
          item.order,

          # meta
          item.keywords,
          item.description,
          item.summary_html,

          # body
          item.question,
          item.html,

          # category
          item.category_name_tree.join("\n"),

          # event
          item.event_name,
          item.event_dates,

          # related pages
          item.related_pages.pluck(:filename).join("\n"),

          # crumb
          item.parent_crumb_urls,

          # contact
          item.label(:contact_state),
          item.contact_group.try(:name),
          item.contact_charge,
          item.contact_tel,
          item.contact_fax,
          item.contact_email,
          item.contact_link_url,
          item.contact_link_name,

          # released
          item.released.try(:strftime, "%Y/%m/%d %H:%M"),
          item.release_date.try(:strftime, "%Y/%m/%d %H:%M"),
          item.close_date.try(:strftime, "%Y/%m/%d %H:%M"),

          # groups
          item.groups.pluck(:name).join("\n"),
          item.permission_level,

          # state
          item.label(:state)
        ]
      end
    end
  end
end
