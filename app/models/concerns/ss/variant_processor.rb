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

  def thumb_url
    thumb.url
  end

  def update_variants
    return if in_disable_variant_processing.present?

    # remove all variants
    variants.each do |variant|
      ::Fs.rm_rf(variant.path) if ::Fs.exist?(variant.path)
    end

    return if !image?
    return if !::Fs.exist?(path)

    self.class.variant_types.each do |variant_name, variant_options|
      variant = variants[variant_name]
      variant_path = variant.path

      # now only supports dimension
      width, height = *variant_options[:dimension]
      SS::ImageConverter.open(path) do |converter|
        converter.resize_to_fit!(width, height)
        Fs.upload(variant_path, converter.to_io)
      end
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

    def [](name)
      Variant.new(file: @file, variant_name: name)
    end

    def each
      @file.class.variant_types.each do |variant_name, _options|
        yield self[variant_name]
      end
    end
  end

  class Variant
    include ActiveModel::Model
    include SS::Locatable
    include SS::ReadableFile

    attr_accessor :file, :variant_name

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
  end
end
