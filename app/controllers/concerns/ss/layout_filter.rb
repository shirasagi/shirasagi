module SS::LayoutFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:navi_view_file) { nil }
    cattr_accessor(:menu_view_file) { nil }
    before_action { @crumbs = [] }
    layout :decide_layout
    helper_method :ss_dialog
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

  def ss_dialog
    request.get_header("HTTP_X_SS_DIALOG")
  end

  def decide_layout
    ss_dialog == 'normal' ? "ss/ajax" : "ss/base"
  end
end
