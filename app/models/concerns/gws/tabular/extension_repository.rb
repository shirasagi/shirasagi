module Gws::Tabular::ExtensionRepository
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    mattr_accessor(:extensions, instance_accessor: false, default: [])
  end

  module ClassMethods
    def extension(ext)
      self.extensions << ext
      ext
    end

    def find_extension_by_path(path)
      extensions.find { |ext| ext.path == path }
    end

    def extension_enabled?(path)
      extension = find_extension_by_path(path)
      return false if extension.blank?

      extension.enabled?
    end

    def extension_options
      extensions.map { |ext| [ ext.i18n_full_name, ext.path ] }
    end
  end
end
