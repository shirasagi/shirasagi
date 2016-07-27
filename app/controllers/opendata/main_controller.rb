class Opendata::MainController < ApplicationController
  include Cms::BaseFilter

  def index
    type = @cur_node.route.sub(/^.*\//, '')
    if type == "app"
      redirect_to opendata_apps_path
    elsif type == "idea"
      redirect_to opendata_ideas_path
    else
      redirect_to opendata_datasets_path
    end
  end
end
