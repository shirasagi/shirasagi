class Gws::Affair2::Admin::MainController < ApplicationController
  include Gws::BaseFilter

  def index
    redirect_to gws_affair2_admin_users_path
  end
end
