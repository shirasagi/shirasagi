class Sys::MainController < ApplicationController
  include Sys::BaseFilter

  navi_view "sys/main/navi"

  def index
    redirect_to sys_info_path
  end
end
