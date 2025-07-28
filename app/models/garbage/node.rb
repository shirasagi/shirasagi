module Garbage::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::GroupPermission

    default_scope ->{ where(route: /^garbage\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/node") }

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Garbage::Addon::Body
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/page") }

    class << self
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.keyword_in params[:name], :name, :kana
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name, :kana, :remark
        end
        if params[:category_ids].present?
          criteria = criteria.in(category_ids: params[:category_ids])
        end

        criteria
      end
    end
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/search") }

    def condition_hash(options = {})
      super(options.reverse_merge(bind: :descendants, category: false, default_location: :only_blank))
    end

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end

  class CategoryList
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/category_list") }
  end

  class Category
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::K5374::Description
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/category") }

    def sort_hash
      return { name: 1 } if sort.blank?
      super
    end
  end

  class AreaList
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Garbage::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/area_list") }
  end

  class Area
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Garbage::Addon::K5374::Collection
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/area") }
  end

  class CenterList
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/center_list") }
  end

  class Center
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Garbage::Addon::K5374::Center
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "garbage/center") }
  end
end
