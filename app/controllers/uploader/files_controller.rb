class Uploader::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Uploader::File

  before_action :create_folder
  before_action :redirect_from_index
  before_action :set_item

  navi_view "uploader/main/navi"

  private
    def create_folder
      return if @model.file(@cur_node.path)
      cur_folder = @model.new path: @cur_node.path, is_dir: true
      raise "404" unless cur_folder.save
    end

    def redirect_from_index
      return unless params[:filename].blank?
      redirect_to action: :file, filename: @cur_node.filename
    end

    def set_item
      filename = ::CGI.unescape params[:filename]
      return unless filename.sub(/\/.+$/, "") == @cur_node.filename
      @item = @model.file "#{@cur_node.site.path}/#{filename}"
      @item.site = @cur_site
      @item.read if @item && @item.text?
    end

    def set_items(path)
      @items = @model.find(path).sort_by
      dirs  = @items.select{ |item| item.directory?  }.sort_by { |item| item.name.capitalize }
      files = @items.select{ |item| !item.directory? }.sort_by { |item| item.name.capitalize }
      @items = dirs + files
      @items.each {|item| item.site = @cur_site }
    end

    def create_files
      files = params[:item][:files]
      files.each do |file|
        next unless file.present?
        path = ::File.join(@cur_site.path, @item.filename, file.original_filename)
        item = @model.new(path: path, binary: file.read)

        if !item.save
          item.errors.each do |n, e|
            @item.errors.add item.name, e
          end
        end
      end
      location = "#{uploader_files_path}/#{@item.filename}"
      render_create @item.errors.empty?, location: location, render: { file: :new_files }
    end

    def create_directory
      path = "#{@item.path}/#{params[:item][:directory]}"
      item = @model.new path: path, is_dir: true

      result = item.save
      unless result
        item.errors.each do |n, e|
          @item.errors.add :path, e
        end
        @directory = params[:item][:directory]
      end

      location = "#{uploader_files_path}/#{@item.filename}"
      render_create result, location: location, render: { file: :new_directory }
    end

  public
    def file
      action = params[:do] || "index"
      raise "404" unless @item
      raise "404" unless %w(index new_directory new_files show edit delete).index(action)
      send action
    end

    def index
      raise "404" unless @item.directory?
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      set_items(@item.path)
      render :index
    end

    def edit
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render :edit
    end

    def show
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      render :show
    end

    def new_files
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render :new_files
    end

    def new_directory
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render :new_directory
    end

    def create
      if params[:item][:directory]
        create_directory
      else
        create_files
      end
    end

    def update
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      filename = params[:item][:filename]
      text = params[:item][:text]
      file = params[:item][:files].find(&:present?)

      if !@item.directory?
        if text
          @item.text = text
        else
          @item.read
        end
      end

      @item.filename = filename if filename && filename =~ /^#{@cur_node.filename}/
      result = @item.save
      @item.path = @item.saved_path unless result
      Fs.binwrite @item.saved_path, file.read if result && file

      location = "#{uploader_files_path}/#{@item.filename}?do=edit"
      render_update true, location: location
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      dirname = @item.dirname
      render_destroy @item.destroy, location: "#{uploader_files_path}/#{dirname}"
    end
end
