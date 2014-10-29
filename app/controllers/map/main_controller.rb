class Map::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to map_pages_path }, only: :index

  public
    def index
      # redirect
    end
end
