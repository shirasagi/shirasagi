module Multilingual::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^multilingual\//) }
  end

  class Lang
    include Cms::Model::Node
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    set_permission_name "cms_nodes"
    validate :validate_locale

    def validate_locale
      unless I18n.available_locales.include?(filename.to_sym)
        errors.add :filename, :invalid_locale
      end
    end

    default_scope ->{ where(route: "multilingual/lang") }
  end
end
