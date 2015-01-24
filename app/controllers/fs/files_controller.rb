class Fs::FilesController < ApplicationController

  private
    def set_item
      path  = params[:filename]
      path << ".#{params[:format]}" if params[:format].present?

      @item = SS::File.find_by id: params[:id], filename: path, state: "public"
    end

  public
    def index
      set_item

      send_data @item.read, type: @item.content_type, filename: @item.filename, disposition: :inline
    end

    def thumb
      set_item

      width  = params[:width].present? ? params[:width].to_i : 120
      height = params[:height].present? ? params[:height].to_i : 90

      require 'RMagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit width, height if image.columns > width || image.rows > height

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue => e
      raise "500"
    end
end
