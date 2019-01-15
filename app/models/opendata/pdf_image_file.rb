class Opendata::PdfImageFile
  include SS::Model::File

  def save_file
    errors.add :in_file, :blank if new_record? && in_file.blank?
    return false if errors.present?
    return if in_file.blank?

    if image?
      list = Magick::ImageList.new
      list.from_blob(in_file.read)
      extract_geo_location(list)
      list.each do |image|
        case SS.config.env.image_exif_option
        when "auto_orient"
          image.auto_orient!
        when "strip"
          image.strip!
        end

        next unless resizing
        width, height = resizing
        image.resize_to_fit! width, height if image.columns > width || image.rows > height
      end
      binary = list.to_blob
    else
      binary = in_file.read
    end
    in_file.rewind

    dir = ::File.dirname(path)
    Fs.mkdir_p(dir) unless Fs.exists?(dir)
    Fs.binwrite(path, binary)
    self.size = binary.length
  end
end
