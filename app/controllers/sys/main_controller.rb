class Sys::MainController < ApplicationController
  include Sys::BaseFilter

  navi_view "sys/main/navi"

  def index
    redirect_to sys_conf_path || sns_mypage_path
  end
end
