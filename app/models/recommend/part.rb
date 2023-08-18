class Recommend::Part
  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^recommend\//) }
  end

  class History
    include ::Cms::Model::Part
    include ::Recommend::Addon::ContentList
    include ::Cms::Addon::Release
    include ::Cms::Addon::GroupPermission
    include ::History::Addon::Backup

    self.ajax_view_only = true
    self.use_sort = false
    self.use_new_days = false

    default_scope ->{ where(route: "recommend/history") }
  end

  class Similarity
    include ::Cms::Model::Part
    include ::Recommend::Addon::ContentList
    include ::Cms::Addon::Release
    include ::Cms::Addon::GroupPermission
    include ::History::Addon::Backup

    self.use_sort = false
    self.use_new_days = false
    self.use_display_target = false

    default_scope ->{ where(route: "recommend/similarity") }
  end
end
