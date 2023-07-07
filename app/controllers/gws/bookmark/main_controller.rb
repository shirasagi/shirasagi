class Gws::Bookmark::MainController < ApplicationController
  include Gws::BaseFilter

  def index
    redirect_to gws_bookmark_items_path(folder_id: @cur_user.bookmark_root_folder(@cur_site))
  end
end
