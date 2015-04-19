module SS::LayoutFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:navi_view_file) { nil }
    cattr_accessor(:menu_view_file) { nil }
    before_action { @crumbs = [] }
  end

  module ClassMethods
    private
      def navi_view(file)
        self.navi_view_file = file
      end

      def menu_view(file)
        self.menu_view_file = file
      end
  end
end
