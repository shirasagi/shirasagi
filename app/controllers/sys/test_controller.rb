# coding: utf-8
class Sys::TestController < ApplicationController
  include Sys::BaseFilter
  
  private
    def set_crumbs
      @crumbs << [:"sys.http_test", sys_test_path]
    end
  
  public
    def index
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)
    end
end
