module Sns::FileFilter
  extend ActiveSupport::Concern

  public
    def index
      @items = []
    end

    def view
      set_item
      send_data @item.read, type: @item.content_type, filename: @item.filename,
        disposition: :inline
    end

    def thumb
      set_item

      require 'RMagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 120, 90 if image.columns > 120 || image.rows > 90

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue
      raise "500"
    end

    def download
      set_item
      send_data @item.read, type: @item.content_type, filename: @item.filename,
        disposition: :attachment
    end

    def create
      @item = @model.new get_params
      render_create @item.save_files, location: { action: :index }
    end
end
