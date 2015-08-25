module Sys::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    before_action { @crumbs << [:"sys.conf", sys_main_path] }
    before_action :set_crumbs
    navi_view "sys/main/navi"
  end

  private
    def set_crumbs
      #
    end
end
