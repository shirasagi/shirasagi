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
      nodes = [self] + related_urgency_nodes.to_a
      nodes.each { |node| node.update_layout(layout.filename) }
    end

    def update_layout(filename)
      index_page = find_index_page
      return if index_page.nil?

      layout = Cms::Layout.site(site).where(filename: filename).first
      return if layout.nil?

      index_page.layout_id = layout.id

      if index_page.is_a?(Cms::Addon::EditLock) && index_page.locked?
        index_page.release_lock(user: index_page.lock_owner, force: true)
      end
      index_page.save
    end
  end
end
