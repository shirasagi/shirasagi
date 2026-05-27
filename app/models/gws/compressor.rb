class Gws::Compressor
  attr_accessor :user, :model, :items, :filename, :name, :root, :path, :url

  DEFAULT_MIN_FILESIZE = 100 * 1_024 * 1_024
  DEFAULT_MIN_COUNT = 100

  def initialize(user, model:, items:, **kwargs)
    model = model.to_s.constantize unless model.is_a?(Class)
    items = model.in(id: items) if items.is_a?(Array)

    self.user     = user
    self.model    = model
    self.items    = items
    self.filename = kwargs[:filename] || "share_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    self.name     = kwargs[:name]

    file = SS::DownloadJobFile.new(user, filename)
    self.root = file.class.root
    self.path = file.path
    self.url  = kwargs[:url] || file.url(name: name)
  end

  class << self
    def default_min_filesize
      deley_download = SS.config.env.deley_download
      return DEFAULT_MIN_FILESIZE if deley_download.blank?
      return DEFAULT_MIN_FILESIZE unless deley_download.key?('min_filesize')

      ret = deley_download['min_filesize'].to_i
      ret >= 0 ? ret : DEFAULT_MIN_FILESIZE
    end

    def default_min_count
      deley_download = SS.config.env.deley_download
      return DEFAULT_MIN_COUNT if deley_download.blank?
      return DEFAULT_MIN_COUNT unless deley_download.key?('min_count')

      ret = deley_download['min_count'].to_i
      ret >= 0 ? ret : DEFAULT_MIN_COUNT
    end

    def min_filesize
      return @min_filesize if instance_variable_defined?(:@min_filesize)
      @min_filesize = default_min_filesize
    end

    def min_count
      return @min_count if instance_variable_defined?(:@min_count)
      @min_count = default_min_count
    end

    if Rails.env.test?
      def min_filesize=(value)
        raise ArgumentError if !value.numeric? || value < 0
        @min_filesize = value
      end

      def min_count=(value)
        raise ArgumentError if !value.numeric? || value < 0
        @min_count = value
      end
    end
  end

  def serialize
    { model: model.name, items: items.map(&:id), filename: filename, name: name, url: url }
  end

  def type
    'application/zip'
  end

  def deley_download?
    sizes = items.map(&:size)
    return true if sizes.sum >= self.class.min_filesize
    return true if sizes.size >= self.class.min_count

    false
  end

  def delay_message
    I18n.t('gws.notice.delay_download_with_message')
  end

  def save
    ::FileUtils.mkdir_p(::File.dirname(path))
    ::File.delete(path) if ::File.exist?(path)

    filenames = []

    Zip::File.open(path, Zip::File::CREATE) do |zip|
      items.each do |item|
        filename = ::File.basename(item.download_filename)
        if filenames.include?(filename)
          filename_without_ext = ::File.basename(filename, ".*")
          extname = ::File.extname(filename)

          filename = "#{filename_without_ext}_#{item.id}"
          if extname.present?
            filename += extname
          end
        end
        filenames << filename
        zip.add(::Fs.zip_safe_name(filename), item.path) if ::File.exist?(item.path)
      end
    end

    ::File.exist?(path)
  end
end
