class Sys::TestController < ApplicationController
  include Sys::BaseFilter

  def index
    redirect_to sys_test_mail_path
  end
end
