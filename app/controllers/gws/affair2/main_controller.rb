class Gws::Affair2::MainController < ApplicationController
  include Gws::BaseFilter

  def index
    redirect_to gws_affair2_attendance_main_path
  end
end
