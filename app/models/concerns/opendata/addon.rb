module Opendata::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Opendata::Node::Category"
      permit_params category_ids: []
    end
  end

  module CategorySetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Cms::Node"
      permit_params st_category_ids: []
    end

    public
      def default_st_categories
        site = self.try(:cur_site) || self.try(:site)
        return [] if site.blank?
        categories = Opendata::Node::Category.site(site).sort(depth: 1, order: 1)
        first_node = categories.first
        return [] if first_node.blank?
        return [first_node.parent].compact
      end

      def st_parent_categories
        categories = []
        parents = st_categories.sort_by { |cate| cate.filename.count("/") }
        while parents.present?
          parent = parents.shift
          parents = parents.map { |c| c.filename !~ /^#{parent.filename}\// ? c : nil }.compact
          categories << parent
        end
        categories
      end
  end

  module Area
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :areas, class_name: "Opendata::Node::Area"
      permit_params area_ids: []
    end
  end

  module DatasetGroup
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :dataset_groups, class_name: "Opendata::DatasetGroup"
      permit_params dataset_group_ids: []
    end
  end

  module Dataset
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :datasets, class_name: "Opendata::Dataset"
      permit_params dataset_ids: []
    end
  end

  module App
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :apps, class_name: "Opendata::App"
      permit_params app_ids: []
    end
  end
end
