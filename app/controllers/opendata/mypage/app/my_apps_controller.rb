class Opendata::Mypage::App::MyAppsController < ApplicationController
  def index
    redirect_to node_nodes_path
  end
end
