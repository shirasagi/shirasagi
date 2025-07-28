module ImageMap::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^image_map\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include ImageMap::Addon::ImageSetting
    include Cms::Addon::PageList
    include Cms::Addon::Form::Node
    include Cms::Addon::ContentQuota
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::ImageResizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "image_map/page") }

    self.use_conditions = false
    self.use_condition_forms = false
    self.use_sort = false
    self.use_loop_html = false
    self.use_new_days = false
    self.use_loop_formats = %i(shirasagi)
    self.use_no_items_display = false
    self.use_substitute_html = false
    self.default_limit = 20
  end
end
