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
      raise "404" if filename != @cur_node.filename && filename !~ /^#{@cur_node.filename}\//
      @item = @model.file "#{@cur_node.site.path}/#{filename}"
      raise "404" unless @item
      @item.site = @cur_site
      @item.read if @item.text?
    end

    def set_items(path)
      @items = @model.search(path, params[:s]).sort_by
      dirs  = @items.select{ |item| item.directory?  }.sort_by { |item| item.name.capitalize }
      files = @items.select{ |item| !item.directory? }.sort_by { |item| item.name.capitalize }
      @items = dirs + files
      @items.each { |item| item.site = @cur_site }
    end

    def create_files
      @files.each do |file|
        next unless file.present?
        path = ::File.join(@cur_site.path, @item.filename, file.original_filename)
        item = @model.new(path: path, binary: file.read, site: @cur_site)

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
      path = "#{@item.path}/#{@directory}"
      item = @model.new(path: path, is_dir: true, site: @cur_site)

      if !item.save
        item.errors.each do |n, e|
          @item.errors.add :path, e
        end
      end
      location = "#{uploader_files_path}/#{@item.filename}"
      render_create @item.errors.empty?, location: location, render: { file: :new_directory }
    end

    def set_params(*keys)
      keys.each { |key| instance_variable_set("@#{key}", params[:item].try(:[], key)) }
    rescue => e
      Rails.logger.debug("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      raise "400"
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

    def delete
      raise "403" unless @cur_node.allowed?(:delete, @cur_user, site: @cur_site)
      render :delete
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
      set_params(:directory, :files)
      if @directory
        create_directory
      elsif @files
        create_files
      else
        raise "400"
      end
    end

    def update
      set_params(:filename, :files, :text, :file)
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      raise "400" unless @filename

      if !@item.directory?
        @text ? (@item.text = @text) : @item.read
      end
      @item.filename = @filename if @filename && @filename =~ /^#{@cur_node.filename}/
      @item.site = @cur_site
      result = @item.save
      @item.path = @item.saved_path unless result

      file = @files.find(&:present?) rescue nil
      file = @file if @file.present?
      Fs.binwrite @item.saved_path, file.read if result && file

      location = "#{uploader_files_path}/#{@item.filename}?do=edit"
      render_update result, location: location
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      if params[:ids].present?
        destroy_all
      else
        render_destroy @item.destroy, location: "#{uploader_files_path}/#{@item.dirname}"
      end
    end

    def destroy_all
      @paths = params[:ids]
      @paths.each do |path|
        item = @model.file("#{@item.path}/#{path}")
        item.destroy
      end
      render_destroy true, location: "#{uploader_files_path}/#{@item.filename}"
    end
end
