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

    before_save :set_view_options

    def set_view_options
      self.mobile_view = "hide"
      self.ajax_view = "enabled"
    end

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
