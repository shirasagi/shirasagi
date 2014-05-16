# coding: utf-8
class Sys::TestController < ApplicationController
  include Sys::BaseFilter
  
  private
    def set_crumbs
      @crumbs << [:"sys.http_test", sys_test_path]
    end
  
  public
    def index
      #
    end
end
