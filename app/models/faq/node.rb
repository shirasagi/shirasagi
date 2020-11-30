module Faq::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^faq\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Cms::Addon::NodeAutoPostSetting
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::TagSetting
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "faq/page") }
  end

  class Search
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "faq/search") }

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
