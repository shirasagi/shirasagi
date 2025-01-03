module Opendata::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::GroupPermission

    default_scope ->{ where(route: /^opendata\//) }
  end

  class Category
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    attr_accessor :count

    default_scope ->{ where(route: "opendata/category") }
  end

  class EstatCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    attr_accessor :count

    default_scope ->{ where(route: "opendata/estat_category") }
  end

  class Area
    include Cms::Model::Node
    include Opendata::Addon::PrefCode
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    attr_accessor :count, :code

    default_scope ->{ where(route: "opendata/area") }
  end

  class Dataset
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::Addon::DatasetPageSetting
    include Opendata::Addon::CategorySetting
    include Opendata::Addon::EstatCategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset") }
  end

  class DatasetCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::DatasetChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset_category") }
  end

  class DatasetEstatCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::DatasetChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset_estat_category") }
  end

  class DatasetArea
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::DatasetChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset_area") }
  end

  class SearchDatasetGroup
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::DatasetChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/search_dataset_group") }
  end

  class SearchDataset
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::DatasetChildNode
    include Opendata::DatasetBulkDownload
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/search_dataset") }
  end

  class DatasetMap
    include Cms::Model::Node
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset_map") }
  end

  class DatasetGraph
    include Cms::Model::Node
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/dataset_graph") }
  end

  class Sparql
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/sparql") }
  end

  class Api
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/api") }
  end

  class App
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::Addon::AppPageSetting
    include Opendata::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/app") }
  end

  class AppCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::AppChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/app_category") }
  end

  class SearchApp
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::AppChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/search_app") }
  end

  class Idea
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::Addon::IdeaPageSetting
    include Opendata::Addon::CategorySetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/idea") }
  end

  class IdeaCategory
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::IdeaChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/idea_category") }
  end

  class SearchIdea
    include Cms::Model::Node
    include Opendata::Addon::ListNodeSetting
    include Cms::Addon::Meta
    include Opendata::IdeaChildNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/search_idea") }
  end

  class Mypage
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/mypage") }
  end

  class Member
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/member") }
  end

  class MyProfile
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Opendata::Addon::ProfileSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "opendata/my_profile") }
  end

  class MyDataset
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    self.use_loop_formats = %i(shirasagi)

    default_scope ->{ where(route: "opendata/my_dataset") }
  end

  class MyFavoriteDataset
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    self.use_loop_formats = %i(shirasagi)

    default_scope ->{ where(route: "opendata/my_favorite_dataset") }
  end

  class MyApp
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    self.use_loop_formats = %i(shirasagi)

    default_scope ->{ where(route: "opendata/my_app") }
  end

  class MyIdea
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    self.use_loop_formats = %i(shirasagi)

    default_scope ->{ where(route: "opendata/my_idea") }
  end
end
