class Gws::Affair2::Management::MainController < ApplicationController
  include Gws::BaseFilter

  def index
    redirect_to gws_affair2_management_time_card_main_path
  end
end
