module SS::Thumbnail
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:thumbs_resizing, instance_accessor: false) { {} }
    attr_accessor :disable_thumb

    default_thumb_size
  end

  module ClassMethods
    def add_thumb_size(name, dimension)
      thumbs_resizing[name] = dimension
    end

    def default_thumb_size(dimension = nil)
      dimension ||= [ SS::ImageConverter::DEFAULT_THUMB_WIDTH, SS::ImageConverter::DEFAULT_THUMB_HEIGHT ]
      add_thumb_size(:normal, dimension)
    end
  end

  def thumbs
    @thumbs ||= ThumbnailCollection.new(self)
  end

  def thumb
    thumbs[:normal]
  end

  def thumb_url
    thumb.url
  end

  def update_thumbnails
    return if disable_thumb.present?

    # remove_all_thumbnails
    thumbs.each do |thumb|
      ::Fs.rm_rf(thumb.path) if ::Fs.exist?(thumb.path)
    end

    return if !image?
    return if !::Fs.exist?(path)

    thumbs.each do |thumb|
      thumbnail_path = thumb.path
      width, height = *thumb.dimension

      SS::ImageConverter.open(path) do |converter|
        converter.resize_to_fit!(width, height)
        Fs.upload(thumbnail_path, converter.to_io)
      end
    end
  end

  class ThumbnailCollection
    include Enumerable

    def initialize(file)
      @file = file
    end

    def count(*several_variants)
      return @file.class.thumbs_resizing.length if several_variants.blank?
      super
    end

    def [](name)
      dimension = @file.class.thumbs_resizing[name]
      return if dimension.blank?

      ThumbnailInfo.new(file: @file, thumbnail_name: name, dimension: dimension)
    end

    def each
      @file.class.thumbs_resizing.each do |name, dimension|
        yield ThumbnailInfo.new(file: @file, thumbnail_name: name, dimension: dimension)
      end
    end
  end

  class ThumbnailInfo
    include ActiveModel::Model
    include SS::Locatable

    attr_accessor :file, :thumbnail_name, :dimension

    class << self
      delegate :root, to: SS::File
    end

    delegate :id, :_id, :site, :site_id, :cur_user, :user, :user_id, :content_type, to: :file

    def physical_name
      "#{id}_#{thumbnail_name}"
    end

    def name
      @name ||= begin
        basename = ::File.basename(file.name, ".*")
        ext = ::File.extname(file.name)
        "#{basename}_#{thumbnail_name}#{ext}"
      end
    end

    def filename
      @filename ||= begin
        basename = ::File.basename(file.filename, ".*")
        ext = ::File.extname(file.filename)
        "#{basename}_#{thumbnail_name}#{ext}"
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
