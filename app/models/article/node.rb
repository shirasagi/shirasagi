module Article::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^article\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeTwitterPostSetting
    include Cms::Addon::NodeLinePostSetting
    include Event::Addon::PageList
    include Cms::Addon::Form::Node
    include Category::Addon::Setting
    include Cms::Addon::TagSetting
    include Cms::Addon::ContentQuota
    include Cms::Addon::ForMemberNode
    include Cms::Addon::OpendataRef::Site
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::ImageResizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "article/page") }

    self.use_condition_forms = true
  end

  class FormExport
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Article::Addon::FormExport
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "article/form_export") }
  end

  class MapSearch
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Article::Addon::MapSearch
    include Article::Addon::MapSearchResult
    include Map::Addon::SearchSetting
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "article/map_search") }

    self.use_condition_forms = true
    self.use_loop_settings = false

    def st_categories_sortable?
      true
    end
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "article/search") }

    def condition_hash(options = {})
      if conditions.present?
        # 指定されたフォルダー内のページが対象
        super
      else
        # サイト内の全ページが対象
        default_site = options[:site] || @cur_site || self.site
        { site_id: default_site.id }
      end
    end
  end
end
