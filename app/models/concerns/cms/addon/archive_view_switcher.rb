module Cms::Addon
  module ArchiveViewSwitcher
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :archive_view, type: Integer, default: 1

      permit_params :archive_view
    end
  end
end
