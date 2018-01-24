class Gws::Memo::Apis::MessagesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Memo::Message

  before_action :set_multi
  before_action :set_inherit_params
  before_action :set_folders

  private

  def set_multi
    @multi = params[:single].blank?
  end

  def set_inherit_params
    @inherit_keys = [:single]
  end

  def set_folders
    @folders = Gws::Memo::Folder.static_items(@cur_user, @cur_site) + Gws::Memo::Folder.user(@cur_user).site(@cur_site)
    @folders.each { |folder| folder.site = @cur_site }
  end

  public

  def index
    s_params = params[:s] || {}

    if s_params[:folder].present?
      @cur_folder = @folders.select { |folder| folder.folder_path == s_params[:folder] }.first
    end
    @cur_folder ||= @folders.first

    @items = @model.folder(@cur_folder, @cur_user).
      site(@cur_site).
      search(s_params).
      page(params[:page]).
      per(50)
  end
end
