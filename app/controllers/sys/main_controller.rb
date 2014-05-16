# coding: utf-8
class Sys::MainController < ApplicationController
  include Sys::BaseFilter
  
  navi_view "sys/main/navi"
  
  public
    def index
      redirect_to sys_sites_path
    end
end
