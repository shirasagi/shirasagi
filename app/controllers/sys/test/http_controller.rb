class Sys::Test::HttpController < ApplicationController
  include Sys::BaseFilter

  menu_view "sys/test/menu"

  private

  def set_crumbs
    @crumbs << ["HTTTP Test", sys_test_http_path]
  end

  public

  def index
    raise "403" unless SS::User.allowed?(:edit, @cur_user)
    raise "403" unless Rails.env.development?
  end
end
