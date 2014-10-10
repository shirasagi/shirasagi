class Sys::TestController < ApplicationController
  include Sys::BaseFilter

  public
    def index
      redirect_to sys_test_http_path
    end
end
