require "csv"

module Opendata::Addon
  module Dataset::Export
    extend ActiveSupport::Concern
    extend SS::Addon

    def estat_category_name_tree
      id_list = estat_categories.pluck(:id)

      ct_list = []
      id_list.each do |id|
        name_list = []
        filename_str = []
        filename_array = Opendata::Node::EstatCategory.where(_id: id).pluck(:filename).first.split(/\//)
        filename_array.each do |filename|
          filename_str << filename
          node = Opendata::Node::EstatCategory.site(site).where(filename: filename_str.join("/")).first
          name_list << node.name if node
        end
        ct_list << name_list.join("/")
      end
      ct_list.sort
    end

    def category_name_tree
      id_list = categories.pluck(:id)

      ct_list = []
      id_list.each do |id|
        name_list = []
        filename_str = []
        filename_array = Opendata::Node::Category.where(_id: id).pluck(:filename).first.split(/\//)
        filename_array.each do |filename|
          filename_str << filename
          node = Opendata::Node::Category.site(site).where(filename: filename_str.join("/")).first
          name_list << node.name if node
        end
        ct_list << name_list.join("/")
      end
      ct_list.sort
    end

    module ClassMethods
      def csv_headers
        %w(
          id name text tags
          category_ids estat_category_ids area_ids
          dataset_group_ids
          released
          contact_state contact_group contact_group_name contact_charge contact_tel contact_fax contact_email
          contact_postal_code contact_address contact_link_url contact_link_name
          related_pages
          groups
        )
      end

      def to_csv
        I18n.with_locale(I18n.default_locale) do
          CSV.generate do |data|
            data << csv_headers.map { |k| t k }
            criteria.each do |item|
              data << csv_line(item)
            end
          end
        end
      end

      def csv_line(item)
        [
          # basic
          item.id,
          item.name,
          item.text,
          item.tags.join("\n"),

          # category
          item.category_name_tree.join("\n"),

          # estat_category
          item.estat_category_name_tree.join("\n"),

          # area
          item.areas.pluck(:name).join("\n"),

          # dataset_group
          item.dataset_groups.pluck(:name).join("\n"),

          # released
          item.released.try { |time| I18n.l(time, format: :picker) },

          # contact
          item.contact_state,
          item.contact_group.try(:name),
          item.contact_group_name,
          item.contact_charge,
          item.contact_tel,
          item.contact_fax,
          item.contact_email,
          item.contact_postal_code,
          item.contact_address,
          item.contact_link_url,
          item.contact_link_name,

          # related pages
          item.related_pages.pluck(:filename).join("\n"),

          # groups
          item.groups.pluck(:name).join("\n")
        ]
      end
    end
  end
end
