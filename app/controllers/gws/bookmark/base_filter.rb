module Gws::Bookmark::BaseFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_root_folder
    before_action :set_folders
    before_action :set_folder
  end

  def set_root_folder
    @root_folder = @cur_user.bookmark_root_folder(@cur_site)
  end

  def set_folders
    @folders = Gws::Bookmark::Folder.site(@cur_site).user(@cur_user)
  end

  def set_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @folder = @folders.find(params[:folder_id])
  end
end
