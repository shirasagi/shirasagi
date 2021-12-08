module Category::Node
  class Base
    include Cms::Model::Node
    include Cms::Addon::ReadableSetting

    class_variable_set(:@@_requires_read_permission_to_read, false)

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::ChildList
    include Cms::Addon::Release
    include Cms::Addon::ReadableSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Category::Addon::Integration
    include Category::Addon::Split

    class_variable_set(:@@_requires_read_permission_to_read, false)

    default_scope ->{ where(route: "category/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Event::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::ImageResizeSetting
    include Cms::Addon::ReadableSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Category::Addon::Integration
    include Category::Addon::Split
    include Cms::ChildList

    class_variable_set(:@@_requires_read_permission_to_read, false)

    default_scope ->{ where(route: "category/page") }
  end
end
