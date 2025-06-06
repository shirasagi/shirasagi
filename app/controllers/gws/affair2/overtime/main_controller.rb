class Gws::Affair2::Overtime::MainController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair2::BaseFilter

  def index
    redirect_to gws_affair2_overtime_workday_files_path(state: "mine")
  end
end
