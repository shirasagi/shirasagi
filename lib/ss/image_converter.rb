class SS::ImageConverter
  class << self
    def process(file, options)
      processor = new(file)

      if options[:image]
        case SS.config.env.image_exif_option
        when "auto_orient"
          processor.auto_orient!
        when "strip"
          processor.strip!
        end

        processor.resize_to_fit!(*options[:resizing]) if options[:resizing].present?
      end

      processor
    end

    def resize_to_fit(ss_file, width, height)
      input = ss_file.path
      output = "#{ss_file.path}.$$"

      env = {}
      options = { in: SS::RakeRunner::NULL_DEVICE, out: SS::RakeRunner::NULL_DEVICE, err: SS::RakeRunner::NULL_DEVICE }

      if SS.config.ss.image_magick.present? && SS.config.ss.image_magick["convert"].present?
        commands = [ SS.config.ss.image_magick["convert"] ]
      else
        commands = [ "/usr/bin/env", "convert" ]
      end
      commands << "-resize"
      commands << "#{width}x#{height}"
      commands << input
      commands << output

      pid = spawn(env, *commands, options)
      _, status = Process.waitpid2(pid)
      if status.success?
        ::FileUtils.move(output, input)
      end

      status.success?
    ensure
      ::FileUtils.rm_f(output)
    end
  end

  def initialize(file)
    @io = ::File.open(file.path, "rb")
    @close = true
  end

  def image_list
    @image_list ||= Magick::ImageList.new(@io)
  end

  def each_image(&block)
    image_list.each(&block)
  end

  def auto_orient!
    each_image do |image|
      image.auto_orient!
    end
  end

  def strip!
    each_image do |image|
      image.strip!
    end
  end

  def resize_to_fit!(width, ehgith)
    each_image do |image|
      image.resize_to_fit!(width, ehgith)
    end
  end

  def to_io
    if @image_list
      StringIO.new(@image_list.to_blob)
    else
      @io
    end
  end

  def geo_location
    extract_geo_location(@image_list) if @image_list
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def close
    @image_list.destroy! if @image_list
    @io.close if @close

    @image_list = nil
    @io = nil
  end

  private

  def extract_geo_location(img_list)
    img = img_list[0]
    exif_lat = img.get_exif_by_entry('GPSLatitude')[0][1]
    exif_lng = img.get_exif_by_entry('GPSLongitude')[0][1]
    return if exif_lat.blank? || exif_lng.blank?

    exif_lat = exif_lat.split(',').map(&:strip)
    exif_lng = exif_lng.split(',').map(&:strip)
    latitude = (Rational(exif_lat[0]) + Rational(exif_lat[1]) / 60 + Rational(exif_lat[2]) / 3600).to_f
    longitude = (Rational(exif_lng[0]) + Rational(exif_lng[1]) / 60 + Rational(exif_lng[2]) / 3600).to_f

    exif_lat_ref = img.get_exif_by_entry('GPSLatitudeRef')[0][1]
    latitude *= -1 if exif_lat_ref == 'S'

    exif_lng_ref = img.get_exif_by_entry('GPSLongitudeRef')[0][1]
    longitude *= -1 if exif_lng_ref == 'W'

    [ latitude, longitude ]
  end
end
