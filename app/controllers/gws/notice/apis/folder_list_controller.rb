class Gws::Notice::Apis::FolderListController < ApplicationController
  include Gws::ApiFilter

  model Gws::Notice::Folder

  before_action :set_mode
  before_action :set_folders
  before_action :set_root_folder
  before_action :set_cur_folder
  before_action :set_items

  private

  def set_mode
    @cur_mode = params[:mode].presence
    @cur_mode = @cur_mode.singularize if @cur_mode
  end

  def set_folders
    @folders ||= begin
      folders = @model.site(@cur_site)

      if @cur_mode == 'manageable'
        folders = folders.allow(:read, @cur_user, site: @cur_site)
      elsif @cur_mode == 'editable'
        folders = folders.member(@cur_user)
      elsif @cur_mode == 'readable'
        folders = folders.readable(@cur_user, site: @cur_site)
      else
        folders = @model.none
      end

      folders
    end
  end

  def set_root_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @root_folder = @folders.find(params[:folder_id])
  end

  def set_cur_folder
    return if params[:id].blank? || params[:id] == '-'
    @cur_folder = @folders.find(params[:id])
  end

  def set_items
    @items ||= begin
      conds = []
      # root folders
      if @root_folder.present?
        conds << { depth: @root_folder.depth + 1 }
      else
        conds << { depth: 1 }
      end

      # sub folders tree
      if @cur_folder.present?
        full_name = ''
        depth = 0
        @cur_folder.name.split('/').each do |part|
          full_name << part
          full_name << '/'
          depth += 1

          conds << { name: /#{Regexp.escape(full_name)}/, depth: depth + 1 }
        end
      end

      @folders.where('$and' =>[{'$or' => conds}]).order_by(depth: 1, order: 1, id: 1)
    end
  end

  def root_items
    @folders.where(depth: 1)
  end

  public

  def index
    render
  end
end
