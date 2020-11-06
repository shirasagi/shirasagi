module Urgency::Addon
  module Layout
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :urgency_default_layout, class_name: "Cms::Layout"
      belongs_to :urgency_mail_page_layout, class_name: "Cms::Layout"
      permit_params :urgency_default_layout_id, :urgency_mail_page_layout_id
      validates :urgency_default_layout_id, presence: true
    end

    def find_index_page
      index_page_filename = parent ? "#{parent.filename}/index.html" : "index.html"
      Cms::Page.site(site).where(filename: index_page_filename, depth: depth).first
    end

    def switch_layout(layout, opts = {})
      index_page = find_index_page
      switch_related = (opts[:switch_related] == false) ? false : true

      return if index_page.blank?

      index_page.layout_id = layout.id
      index_page.save

      switch_related_site(layout) if switch_related
    end

    def switch_related_site(layout)
      related_urgency_sites.each do |site|
        related_node = self.class.find_related_urgency_node(site)
        related_layout = self.class.find_related_urgency_layout(site, layout)

        if related_node && related_layout
          related_node.switch_layout(related_layout, switch_related: false)
        end
      end
    end

    module ClassMethods
      def find_related_urgency_node(site)
        Urgency::Node::Layout.site(site).order_by(depth: 1, id: 1).first
      end

      def find_related_urgency_layout(site, layout)
        Cms::Layout.site(site).where(filename: layout.filename).first
      end
    end
  end
end
