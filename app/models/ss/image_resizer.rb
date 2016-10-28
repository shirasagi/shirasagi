class SS::ImageResizer
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user
  attr_accessor :resizing

  def resizing
    (@resizing && @resizing.size == 2) ? @resizing.map(&:to_i) : nil
  end

  def resizing=(s)
    @resizing = (s.class == String) ? s.split(",") : s
  end

  def resize(file)
    return false unless file.image?
    return false unless resizing

    list = Magick::ImageList.new(file.path)
    width, height = resizing
    modified = false
    list.each do |image|
      if image.columns > width || image.rows > height
        image.resize_to_fit! width, height
        modified = true
      end
    end

    if modified
      binary = list.to_blob
      Fs.binwrite(file.path, binary)
      file.update_attribute(:size, binary.length)
    end

    true
  end
end
