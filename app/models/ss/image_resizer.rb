class SS::ImageResizer
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user
  attr_accessor :resizing

  def resizing
    (@resizing && @resizing.size == 2) ? @resizing.map(&:to_i) : nil
  end

  def resizing=(size)
    @resizing = (size.class == String) ? size.split(",") : size
  end

  def resize(file)
    return false unless file.image?
    return false unless resizing

    file.shrink_image_to(*resizing)
  end
end
