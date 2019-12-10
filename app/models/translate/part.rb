module Translate::Part
  class Tool
    include Cms::Model::Part
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "translate/tool") }

    before_save :set_view_options

    def set_view_options
      self.mobile_view = "hide"
      self.ajax_view = "enabled"
    end
  end
end
