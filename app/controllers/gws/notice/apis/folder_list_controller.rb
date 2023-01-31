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
      case @cur_mode
      when 'manageable'
        @model.for_post_manager(@cur_site, @cur_user)
      when 'editable'
        @model.for_post_editor(@cur_site, @cur_user)
      when 'readable'
        @model.for_post_reader(@cur_site, @cur_user)
      else
        @model.none
      end
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
        conds << { name: /^#{::Regexp.escape(@root_folder.name)}\//, depth: @root_folder.depth + 1 }
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

          conds << { name: /^#{::Regexp.escape(full_name)}/, depth: depth + 1 }
        end
      end

      @folders.where('$and' =>[{'$or' => conds}]).tree_sort
    end
  end

  public

  def index
    render
  end
end
