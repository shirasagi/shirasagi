module Cms::Addon
  module ArchiveViewSwitcher
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :archive_view, type: String, default: "list"
      permit_params :archive_view
    end

    def archive_view_options
      I18n.t('cms.options.archive_view').map { |k, v| [v, k] }
    end
  end
end
