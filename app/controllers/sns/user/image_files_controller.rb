class Sns::User::ImageFilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter
  include Sns::FileFilter
  include SS::AjaxFilter

  model SS::UserFile

  private
    def fix_params
      { cur_user: @cur_user }
    end

  public
    def index
      cond = { content_type: /^image\// }

      @items = @model.user(@cur_user).
        where(cond).
        order_by(_id: -1).
        page(params[:page]).per(20)
    end

    def select
      set_item

      item = SS::TempFile.new

      @item.attributes.each do |key, val|
        next if key =~ /^(id|file_id)$/
        item.send("#{key}=", val) unless item.send(key)
      end

      item.state   = "public"
      item.in_file = @item.uploaded_file
      item.save
      @item = item

      render layout: !request.xhr?
    end

    def public_thumb
      set_item

      require 'RMagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 256, 192 if image.columns > 256 || image.rows > 192

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue
      raise "500"
    end
end
