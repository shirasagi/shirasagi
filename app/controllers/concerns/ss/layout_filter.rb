module SS::LayoutFilter
  extend ActiveSupport::Concern

  VIEW_ACCESSORS = %i[navi menu content_head mod_navi].freeze

  included do
    cattr_reader(:view_files, instance_reader: false) { {} }
    before_action { @crumbs = [] }

    VIEW_ACCESSORS.each do |s|
      define_method("#{s}_view_file") do
        self.class.view_files[s]
      end
    end
  end

  module ClassMethods
    private

    VIEW_ACCESSORS.each do |s|
      define_method("#{s}_view") do |file|
        self.view_files[s] = file
      end
    end
  end
end
