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

    default_scope ->{ where(route: "recommend/history") }
  end

  class Recommend
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

    default_scope ->{ where(route: "recommend/recommend") }
  end
end
