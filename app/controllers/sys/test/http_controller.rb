class Sys::Test::HttpController < ApplicationController
  include Sys::BaseFilter

  menu_view "sys/test/menu"

  private
    def set_crumbs
      @crumbs << ["HTTTP Test", sys_test_mail_path]
    end

  public
    def index
      raise "403" unless Sys::User.allowed?(:edit, @cur_user)
    end
end
