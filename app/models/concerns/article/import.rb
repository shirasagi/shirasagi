require "csv"

module Article::Import
  extend ActiveSupport::Concern

  def category_name_tree
    id_list = categories.where(route: /^category\//).pluck(:id)

    ct_list = []
    id_list.each do |id|
      name_list = []
      filename_str = []
      filename_array = Cms::Node.where(_id: id).pluck(:filename).first.split(/\//)
      filename_array.each do |filename|
        filename_str << filename
        node = Cms::Node.site(site).where(filename: filename_str.join("/")).first
        name_list << node.name if node
      end
      ct_list << name_list.join("/")
    end
    ct_list.sort
  end

  module ClassMethods
    def enum_csv(options = {})
      drawer = SS::Csv.draw do
        # basic
        column :filename do
          body { |item| item.basename }
        end
        column :name
        column :index_name
        column :layout do
          body { |item| Cms::Layout.where(id: item.layout_id).pluck(:name).first }
        end
        column :body_layout_id do
          body { |item| Cms::BodyLayout.where(id: item.body_layout_id).pluck(:name).first }
        end
        column :order

        # meta
        column :keywords
        column :description
        column :summary_html

        # body
        column :html
        column :body_part do
          body { |item| item.body_parts.map{ |body| body.gsub("\t", '    ') }.join("\t") }
        end

        # category
        column :categories do
          body { |item| item.category_name_tree.join("\n") }
        end

        # event
        column :event_name
        column :event_dates
        column :event_deadline

        # related pages
        column :related_pages do
          body { |item| item.related_pages.pluck(:filename).join("\n") }
        end

        # crumb
        column :parent_crumb do
          body { |item| item.parent_crumb_urls }
        end

        # contact
        column :contact_state, type: :label
        column :contact_group do
          body { |item| item.contact_group.try(:name) }
        end
        column :contact_charge
        column :contact_tel
        column :contact_fax
        column :contact_email
        column :contact_link_url
        column :contact_link_name

        # released
        column :released
        column :release_date
        column :close_date

        # groups
        column :groups do
          body { |item| item.groups.pluck(:name).join("\n") }
        end
        column :permission_level

        # state
        column :state, type: :label
      end

      drawer.enum(self, options)
    end
  end
end
