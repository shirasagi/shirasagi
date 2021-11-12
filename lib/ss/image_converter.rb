# this class doesn't support grid_fs for performance reason
class SS::ImageConverter
  DEFAULT_THUMB_WIDTH = 120
  DEFAULT_THUMB_HEIGHT = 90

  private_class_method :new

  class << self
    def open(path, ext = nil)
      ret = new(::File.open(path, "rb"), ext || ::File.extname(path), true)
      return ret unless block_given?

      begin
        yield ret
      ensure
        ret.close
      end
    end

    def read(binary, ext = nil)
      ret = new(StringIO.new(binary), ext, false)
      return ret unless block_given?

      begin
        yield ret
      ensure
        ret.close
      end
    end

    def attach(io, ext = nil)
      ret = new(io, ext, false)
      return ret unless block_given?

      begin
        yield ret
      ensure
        ret.close
      end
    end

    def image_mime_type?(mime_type)
      return false if mime_type.blank?
      mime_type.start_with?('image/')
    end

    def exif_image_mime_type?(mime_type)
      return false if mime_type.blank?
      %w(image/jpeg image/tiff).include?(mime_type)
    end

    def mime_type_from_head(pathname_or_io, **options)
      Marcel::MimeType.for(pathname_or_io, **options)
    rescue SystemCallError
      nil
    end

    def image?(pathname_or_io, **options)
      image_mime_type?(mime_type_from_head(pathname_or_io, **options))
    end

    def exif_image?(pathname_or_io, **options)
      exif_image_mime_type?(mime_type_from_head(pathname_or_io, **options))
    end
  end

  def initialize(io, ext, close_io)
    @io = io
    @ext = ext
    @close_io = close_io
    @commands = []
    @image = nil
    @io_result = nil
  end

  def mime_type
    @mime_type ||= SS::ImageConverter.mime_type_from_head(@io, extension: @ext)
  end

  def image?
    SS::ImageConverter.image_mime_type?(mime_type)
  end

  def exif_image?
    SS::ImageConverter.exif_image_mime_type?(mime_type)
  end

  def apply_defaults!(options)
    if exif_image?
      case SS.config.env.image_exif_option
      when "auto_orient"
        auto_orient!
      when "strip"
        strip!
      end
    end

    resize_to_fit!(*options[:resizing]) if options[:resizing].present?
    quality!(options[:quality]) if options[:quality].present?

    self
  end

  def auto_orient!
    @commands << [ :auto_orient ]
    self
  end

  def strip!
    @commands << [ :strip ]
    self
  end

  def resize_to_fit!(*args)
    width = args.shift || DEFAULT_THUMB_WIDTH
    height = args.shift || DEFAULT_THUMB_HEIGHT

    @commands << [ :_resize, width, height ]
    self
  end

  def quality!(quality)
    @commands << [:quality, quality ]
    self
  end

  # other ImageMagick / GraphicsMagick methods
  #
  # def rotate!(degrees)
  #   @commands << [ :rotate, degrees ]
  #   self
  # end
  #
  # def crop!(geometry)
  #   @commands << [ :crop, geometry ]
  #   self
  # end
  #
  # def geometry!(geometry)
  #   @commands << [ :geometry, geometry ]
  #   self
  # end
  #
  # def format!(type)
  #   @commands << [ :format, type ]
  #   self
  # end
  #
  # def size!(geometry)
  #   @commands << [ :size, geometry ]
  #   self
  # end
  #
  # def wave!(amplitude)
  #   @commands << [ :wave, amplitude ]
  #   self
  # end
  #
  # def gravity!(type)
  #   @commands << [ :gravity, type ]
  #   self
  # end
  #
  # def pointsize!(value)
  #   @commands << [ :pointsize, value ]
  #   self
  # end
  #
  # def implode!(factor)
  #   @commands << [ :implode, factor ]
  #   self
  # end
  #
  # def label!(name)
  #   @commands << [ :label, name ]
  #   self
  # end
  #
  # def label!(name)
  #   @commands << [ :label, name ]
  #   self
  # end
  #
  # def font!(name)
  #   @commands << [ :font, name ]
  #   self
  # end
  #
  # def evaluate!(operator, value)
  #   @commands << [ :evaluate, operator, value ]
  #   self
  # end

  def to_io
    return @io unless image?
    return @io if @commands.blank?

    @image = MiniMagick::Image.read(@io, @ext)
    @image.combine_options do |b|
      @commands.each do |command|
        method = command.shift
        if method == :_resize
          width, height = *command
          if @image.width > width || @image.height > height
            geometry = "#{width}x#{height}"
            b.resize geometry
          end
        else
          b.send(method, *command)
        end
      end
    end
    @commands.clear

    if @io_result
      @io_result.close
      @io_result = nil
    end

    @io_result = ::File.open(@image.path, "rb")
  end

  def to_enum
    Class.new do
      attr_reader :converter

      def initialize(converter, io)
        @converter = converter
        @io = io
      end

      def each(&block)
        @io.each(&block)
      end

      def close
        @converter.close
      end
    end.new(self, self.to_io)
  end

  def geo_location
    extract_geo_location(@image) if @image
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def close
    @io_result.close if @io_result
    @image.destroy! if @image
    @io.close if @close_io

    @io_result = nil
    @image = nil
    @io = nil
  end

  private

  def extract_geo_location(img)
    exif = img.exif
    exif_lat = exif['GPSLatitude']
    exif_lng = exif['GPSLongitude']
    return if exif_lat.blank? || exif_lng.blank?

    exif_lat = exif_lat.split(',').map(&:strip)
    exif_lng = exif_lng.split(',').map(&:strip)
    latitude = (Rational(exif_lat[0]) + Rational(exif_lat[1]) / 60 + Rational(exif_lat[2]) / 3600).to_f
    longitude = (Rational(exif_lng[0]) + Rational(exif_lng[1]) / 60 + Rational(exif_lng[2]) / 3600).to_f

    exif_lat_ref = exif['GPSLatitudeRef']
    latitude *= -1 if exif_lat_ref == 'S'

    exif_lng_ref = exif['GPSLongitudeRef']
    longitude *= -1 if exif_lng_ref == 'W'

    [ latitude, longitude ]
  end
end
