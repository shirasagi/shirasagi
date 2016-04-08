module Gws::FileFilter
  extend ActiveSupport::Concern
  include SS::FileFilter

  included do
    prepend_view_path "app/views/gws/crud/files"
  end
end
