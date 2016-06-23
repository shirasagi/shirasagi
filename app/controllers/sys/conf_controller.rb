class Sys::ConfController < ApplicationController
  include Sys::BaseFilter

  private
    def set_crumbs
      @crumbs << [:"sys.info", sys_conf_path]
    end

  public
    def index
    end
end
