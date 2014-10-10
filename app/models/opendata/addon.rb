module Opendata::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 300

    included do
      embeds_ids :categories, class_name: "Opendata::Node::Category"
      permit_params category_ids: []
    end
  end

  module DatasetGroup
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 301

    included do
      embeds_ids :dataset_groups, class_name: "Opendata::DatasetGroup"
      permit_params dataset_group_ids: []
    end
  end

  module Area
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 302

    included do
      embeds_ids :areas, class_name: "Opendata::Node::Area"
      permit_params area_ids: []
    end
  end

  module DatasetNode
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 10

    included do
      belongs_to :dataset_layout, class_name: "Cms::Layout"
      permit_params :dataset_layout_id
    end
  end

  module Dataset
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 310

    included do
      embeds_ids :datasets, class_name: "Opendata::Dataset"
      permit_params dataset_ids: []
    end
  end

  module App
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 311

    included do
      embeds_ids :apps, class_name: "Opendata::App"
      permit_params app_ids: []
    end
  end

  module Tag
    extend SS::Addon
    extend ActiveSupport::Concern

    set_order 500

    included do
      field :tags, type: SS::Extensions::Words
      permit_params :tags, keywords: []
    end
  end

  module Release
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 501

    included do
      validate :validate_release_date
    end

    def validate_release_date
      if public? && released.blank?
        self.released = Time.now
      end
    end
  end
end
