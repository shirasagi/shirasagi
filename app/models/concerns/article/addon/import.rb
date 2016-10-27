require "csv"

module Article::Addon
  module Import
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
          html
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
        csv = CSV.generate do |data|
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
        line << Cms::Layout.where(_id: item.layout_id).map(&:name).first
        line << item.order

        # meta
        line << item.keywords
        line << item.description
        line << item.summary_html

        # body
        line << item.html

        # category
        line << item.category_name_tree.join("\n")

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

        line
      end
    end
  end
end
