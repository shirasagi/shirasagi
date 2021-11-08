module Sys::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter
  include Sys::LinkFilter

  included do
    before_action { @crumbs << [t("sys.conf"), sys_main_path] }
    before_action :set_crumbs
    navi_view "sys/main/navi"
  end

  private

  def set_crumbs
  end
end
