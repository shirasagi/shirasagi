module SS::VariantProcessor
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:variant_types, instance_accessor: false)
    self.variant_types = {
      thumb: { dimension: [ SS::ImageConverter::DEFAULT_THUMB_WIDTH, SS::ImageConverter::DEFAULT_THUMB_HEIGHT ] }
    }
    attr_accessor :in_disable_variant_processing
  end

  module ClassMethods
    def add_thumb_size(name, dimension)
      variant_types[name] = { dimension: dimension }
    end

    def default_thumb_size(dimension)
      add_thumb_size(:thumb, dimension)
    end
  end

  def variants
    @variants ||= VariantCollection.new(self)
  end

  def thumb
    variants[:thumb]
  end

  delegate :url, to: :thumb, prefix: true

  def update_variants
    return if in_disable_variant_processing.present?

    # remove all variants
    ::Dir.glob("#{::File.dirname(path)}/*") do |variant_path|
      next if variant_path == path
      ::Fs.rm_rf(variant_path)
    end

    return if !image?
    return if !::Fs.exist?(path)

    self.class.variant_types.each do |variant_name, variant_options|
      variant = variants[variant_name]
      variant.create!
    end
  end

  class VariantCollection
    include Enumerable

    def initialize(file)
      @file = file
    end

    def count(*args)
      return @file.class.variant_types.length if args.blank?
      super
    end

    def [](name_or_options)
      case name_or_options
      when String, Symbol
        name_or_options = name_or_options.to_sym
        variant_type = @file.class.variant_types.find do |name, _variant_options|
          name == name_or_options
        end
        variant_type ? Variant.new(file: @file, variant_name: variant_type[0], variant_options: variant_type[1]) : nil
      when Hash
        # currently width and height are only supported
        width = name_or_options[:width]
        height = name_or_options[:height]
        return if !width.numeric? || !height.numeric?

        variant_type = @file.class.variant_types.find do |_name, variant_options|
          next if variant_options[:dimension].blank?
          variant_options[:dimension][0] == width && variant_options[:dimension][1] == height
        end

        return Variant.new(file: @file, variant_name: variant_type[0], variant_options: variant_type[1]) if variant_type

        Variant.new(file: @file, variant_name: "#{width}x#{height}", variant_options: { dimension: [ width, height ] })
      else
        nil
      end
    end

    def each
      @file.class.variant_types.each do |variant_name, variant_options|
        yield Variant.new(file: @file, variant_name: variant_name, variant_options: variant_options)
      end
    end

    def from_filename(name_or_filename)
      extname = ::File.extname(name_or_filename)
      name_or_filename = ::File.basename(name_or_filename, ".*")
      spec_separator = name_or_filename.rindex("_")
      return unless spec_separator

      spec = name_or_filename[spec_separator + 1..-1]
      return if spec.blank?

      name_or_filename = name_or_filename[0..spec_separator - 1]
      name_or_filename = "#{name_or_filename}#{extname}"
      return if @file.name != name_or_filename && @file.filename != name_or_filename

      variant = self[spec]
      return variant if variant

      width, height = spec.split("x", 2)
      return if !width.numeric? || !height.numeric?

      width = width.to_i
      height = height.to_i
      return if width <= 0 || width >= 3000 || height <= 0 || height >= 3000

      self[{ width: width, height: height }]
    end
  end

  class Variant
    include ActiveModel::Model
    include SS::Locatable
    include SS::ReadableFile

    attr_accessor :file, :variant_name, :variant_options

    class << self
      delegate :root, to: SS::File
    end

    delegate :id, :_id, :site, :site_id, :cur_user, :user, :user_id, :content_type, :updated, :created, to: :file

    def physical_name
      "#{id}_#{variant_name}"
    end

    def name
      @name ||= begin
        basename = ::File.basename(file.name, ".*")
        ext = ::File.extname(file.name)
        "#{basename}_#{variant_name}#{ext}"
      end
    end

    def filename
      @filename ||= begin
        basename = ::File.basename(file.filename, ".*")
        ext = ::File.extname(file.filename)
        "#{basename}_#{variant_name}#{ext}"
      end
    end

    def size
      return 0 unless ::Fs.exist?(path)
      @size ||= ::Fs.size(path)
    end

    def image_dimension
      return unless Fs.exist?(path)
      return unless @file.image?

      ::FastImage.size(path) rescue nil
    end

    def create!
      return true if ::Fs.exist?(path)

      width, height = *variant_options[:dimension]
      SS::ImageConverter.open(file.path) do |converter|
        converter.resize_to_fit!(width, height)
        Fs.upload(path, converter.to_io)
      end

      true
    end
  end
end
