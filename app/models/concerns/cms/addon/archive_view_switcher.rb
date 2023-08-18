module Cms::Addon
  module ArchiveViewSwitcher
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :archive_view, type: String

      permit_params :archive_view
    end

    def archive_view_options
      [
        [I18n.t('cms.list_view'), 'list'],
        [I18n.t('cms.calendar_view'), 'calendar']
      ]
    end
  end
end
