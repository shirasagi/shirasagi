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

    def switch_layout(layout)
      index_page = find_index_page
      return if index_page.blank?

      index_page.layout_id = layout.id
      index_page.save
    end
  end
end
