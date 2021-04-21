module Opendata::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      cattr_accessor(:required_categories, instance_accessor: false) { true }
      embeds_ids :categories, class_name: "Opendata::Node::Category", metadata: { on_copy: :safe }
      permit_params category_ids: []
      validates :category_ids, presence: true, if: ->{ self.class.required_categories }

      validate :validate_categories_limit
    end

    def validate_categories_limit
      return unless try(:cur_node)

      node = cur_node.becomes_with_route
      limit = node.try(:categories_limit).to_i

      return if limit <= 0

      compacted = []
      filenames = categories.pluck(:filename)
      filenames.each do |filename|
        start_with = filenames.select { |item| item.start_with?(filename) }
        if start_with.size == 1
          compacted << start_with.first
        end
      end
      node_size = compacted.size

      if node_size > limit
        errors.add :base, I18n.t("opendata.errors.messages.too_many_categories", limit: limit)
      end
    end
  end

  module EstatCategory
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :estat_categories, class_name: "Opendata::Node::EstatCategory", metadata: { on_copy: :safe }
      permit_params estat_category_ids: []

      validate :validate_estat_categories_limit
    end

    def validate_estat_categories_limit
      return unless try(:cur_node)

      node = cur_node.becomes_with_route
      limit = node.try(:estat_categories_limit).to_i

      return if limit <= 0

      compacted = []
      filenames = estat_categories.pluck(:filename)
      filenames.each do |filename|
        start_with = filenames.select { |item| item.start_with?(filename) }
        if start_with.size == 1
          compacted << start_with.first
        end
      end
      node_size = compacted.size

      if node_size > limit
        errors.add :base, I18n.t("opendata.errors.messages.too_many_estat_categories", limit: limit)
      end
    end
  end

  module CategorySetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_categories, class_name: "Cms::Node"
      permit_params st_category_ids: []

      field :categories_limit, default: 0
      permit_params :categories_limit
    end

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
        parents = parents.map { |c| /^#{::Regexp.escape(parent.filename)}\//.match?(c.filename) ? nil : c }.compact
        categories << parent
      end
      categories
    end
  end

  module EstatCategorySetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_estat_categories, class_name: "Cms::Node"
      permit_params st_estat_category_ids: []

      field :estat_categories_limit, default: 0
      permit_params :estat_categories_limit
    end

    def default_st_estat_categories
      site = self.try(:cur_site) || self.try(:site)
      return [] if site.blank?
      categories = Opendata::Node::EstatCategory.site(site).sort(depth: 1, order: 1)
      first_node = categories.first
      return [] if first_node.blank?
      return [first_node.parent].compact
    end

    def st_parent_estat_categories
      categories = []
      parents = st_estat_categories.sort_by { |cate| cate.filename.count("/") }
      while parents.present?
        parent = parents.shift
        parents = parents.map { |c| /^#{::Regexp.escape(parent.filename)}\//.match?(c.filename) ? nil : c }.compact
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

    def pref_codes
      codes = areas.map { |area| area.pref_code }.compact
      codes.partition { |code| code.city.blank? }
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
