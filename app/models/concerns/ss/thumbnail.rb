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

  def thumbnail_path(name = nil)
    name ||= :normal
    "#{self.class.root}/ss_files/" + id.to_s.chars.join("/") + "/_/#{id}_#{name}"
  end

  def thumb(name = nil)
    path = thumbnail_path(name)
    return unless ::Fs.exist?(path)

    OpenStruct.new(
      name: self.name,
      filename: self.filename,
      content_type: self.content_type,
      path: path,
      size: ::Fs.size(path),
    )
  end

  def update_thumbnails
    return if disable_thumb.present?

    # remove_all_thumbnails
    self.class.thumbs_resizing.each do |name, _dimension|
      thumbnail_path = thumbnail_path(name)
      ::Fs.rm_rf(thumbnail_path) if ::Fs.exist?(thumbnail_path)
    end

    return if !image?
    return if !::Fs.exist?(path)

    ext = ::File.extname(filename)
    self.class.thumbs_resizing.each do |name, dimension|
      thumbnail_path = thumbnail_path(name)
      SS::ImageConverter.attach(path, ext: ext) do |converter|
        converter.apply_defaults!(resizing: dimension)
        Fs.upload(thumbnail_path, converter.to_io)
      end
    end
  end
end
