class Sys::InfoController < ApplicationController
  include Sys::BaseFilter

  private
    def set_crumbs
      @crumbs << [:"sys.info", sys_info_path]
    end

  public
    def index
    end
end
