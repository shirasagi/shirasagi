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

    def translate_target_options(target = nil)
      if target
        options = [ [ I18n.t("translate.views.show_original"), "" ] ]
      else
        options = [ [I18n.t("translate.views.select_lang"), ""] ]
      end
      options += site.translate_targets.map do |item|
        [item.name, item.code]
      end
      options
    end
  end
end
