module Category::Addon
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Category::Node::Base"
      permit_params st_category_ids: []
      define_method(:st_categories) do
        if st_categories_sortable?
          items = ::Category::Node::Base.in(id: st_category_ids).to_a
          return st_category_ids.map { |id| items.find { |item| item.id == id } }
        end

        ::Category::Node::Base.in(id: st_category_ids)
      end
    end

    def st_categories_sortable?
      false
    end

    def st_parent_categories
      categories = []
      parents = st_categories.sort_by { |cate| cate.filename.count("/") }
      while parents.present?
        parent = parents.shift
        parents = parents.map { |c| /^#{::Regexp.escape(parent.filename)}\//.match?(c.filename) ? nil : c }.compact
        categories << parent
      end
      categories
    end
  end
end
