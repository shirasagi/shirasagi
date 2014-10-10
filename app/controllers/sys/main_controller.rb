class Sys::MainController < ApplicationController
  include Sys::BaseFilter

  navi_view "sys/main/navi"

  public
    def index
      redirect_to sys_info_path
    end
end
