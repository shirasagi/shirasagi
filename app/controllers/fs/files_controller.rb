# coding: utf-8
class Fs::FilesController < ApplicationController
  
  private
    def set_item
      path  = params[:filename]
      path << ".#{params[:format]}" if params[:format].present?
      
      @item = SS::File.find_by id: params[:id], filename: path
    end
    
  public
    def index
      set_item
      
      send_data @item.read, type: @item.content_type, filename: @item.filename, disposition: :inline
    end
    
    def thumb
      set_item
      
      require 'RMagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 120, 90 if image.columns > 120 || image.rows > 90
      
      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue => e
      raise "500"
    end
end
