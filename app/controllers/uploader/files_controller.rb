class Uploader::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Uploader::File

  navi_view "uploader/main/navi"

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      if !@model.file @cur_node.path
        cur_dir = @model.new path: @cur_node.path, is_dir: true
        raise "404" if !cur_dir.save
      end
        redirect_to action: :show, filename: @cur_node.filename
    end

    def show

      if @item.filename == @cur_node.filename && params[:do] =~ /edit|show|delete/
        raise "404"
      end

      if params[:do] =~ /show/ || @item.directory?
        raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      else
        raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      end

      actions = %w(edit show delete new_directory new_files)
      if actions.include?(params[:do])
        index = actions.index(params[:do])
        render actions[index].to_sym
      elsif @item.directory?
        set_items
        render :index
      else
        raise "404"
      end
    end

    def create
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      set_item
      if params[:item].present?
        if params[:item][:directory]
          create_directory
          return
        elsif params[:item][:files]
          create_files
          return
        end
      end

      set_items
      render file: :index
    end

    def update
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      filename = params[:item][:filename]
      text = params[:item][:text]

      if !@item.directory?
        if text
          @item.text = text
        else
          @item.read
        end
      end

      @item.filename = filename if filename && filename =~ /^#{@cur_node.filename}/

      if @item.save
        render_update true, location: "#{uploader_files_path}/#{@item.filename}?do=edit"
      else
        @item.path = @item.saved_path
        render file: :edit
      end
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

      dirname = @item.dirname
      @item.destroy
      render_destroy true, location: "#{uploader_files_path}/#{dirname}"
    end

  private
    def create_directory
      path = "#{@item.path}/#{params[:item][:directory]}"
      item = @model.new path: path,  is_dir: true

      if item.save
        render_create true, location: "#{uploader_files_path}/#{@item.filename}"
      else
        item.errors.each do |n, e|
          @item.errors.add :path, e
        end
        @directory = params[:item][:directory]
        render :new_directory
      end
    end

    def create_files
      params[:item][:files].each do |file|
        path = "#{@cur_site.path}/#{@item.filename}/#{file.original_filename}"
        item = @model.new(path: path, binary: file.read)

        if !item.save
          item.errors.each do |n, e|
            @item.errors.add item.name, e
          end
        end
      end

      if @item.errors.empty?
        render_create true, location: "#{uploader_files_path}/#{@item.filename}"
      else
        render :new_files
      end
    end

    def set_items
      if @item

        @items = @model.find(@item.path).sort_by
        dirs  = @items.select{ |item| item.directory?  }.sort_by { |item| item.name.capitalize }
        files = @items.select{ |item| !item.directory? }.sort_by { |item| item.name.capitalize }
        @items =  dirs + files
      else
        @items = []
      end
    end

    def set_item
      filename = "#{params[:filename]}"

      raise "404" if filename != @cur_node.filename && filename !~ /^#{@cur_node.filename}\//
      @item = @model.file "#{@cur_node.site.path}/#{filename}"
      raise "404" if !@item

      if @item
        @item.read if @item.text?
      end
    end
end
