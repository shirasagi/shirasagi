class Sys::Diag::MainController < ApplicationController
  include Sys::BaseFilter

  def index
    redirect_to sys_diag_mails_path
  end
end
