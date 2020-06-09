class Uploader::File
  include ActiveModel::Model

  attr_accessor :path, :binary, :site
  attr_reader :saved_path, :is_dir

  validates :path, presence: true
  validates :filename, length: { maximum: 2000 }

  validate :validate_filename
  validate :validate_scss
  validate :validate_coffee
  validate :validate_size

  def save
    return false unless valid?
    @binary = self.class.remove_exif(binary) if binary && exif_image?
    if saved_path && path != saved_path # persisted AND path chenged
      Fs.binwrite(saved_path, binary) unless directory?
      Fs.mv(saved_path, path)
    else
      directory? ? Fs.mkdir_p(path) : Fs.binwrite(path, binary)
    end
    @saved_path = @path
    compile_scss if @css
    compile_coffee if @js
    return true
  rescue => e
    errors.add :path, ":" + e.message
    return false
  end

  def destroy
    Fs.rm_rf path
  end

  def read
    @binary = Fs.binread path if !directory?
  end

  def size
    Fs.size path
  end

  def updated
    Fs.stat(path).mtime
  end

  def content_type
    Fs.content_type path
  end

  def ext
    File.extname(path)
  end

  def directory?
    is_dir == true
  end

  def text
    require 'nkf'
    NKF.nkf '-w Lw', @binary
  end

  def text=(str)
    @binary = str
  end

  def text?
    ext =~ /^\.?(txt|css|scss|coffee|js|htm|html|php)$/
  end

  def image?
    content_type.to_s.start_with?('image/')
  end

  def exif_image?
    image? && ext =~ /^(jpe?g|tiff?)$/i
  end

  def link
    return path.sub(/.*?\/_\//, "/") if Fs.mode == :grid_fs
    "/sites#{path.sub(/^#{::Regexp.escape(SS::Site.root)}/, '')}"
  end

  def filename
    return path.sub(/.*?\/_\//, "") if Fs.mode == :grid_fs
    path.sub(/^#{site.path}\//, "")
  end

  def filename=(fname)
    @path = "#{path.sub(filename, '')}#{fname}"
  end

  def basename
    ::File.basename(path)
  end

  def name
    path.sub(/^.*\//, "")
  end

  def parent
    /\//.match?(path) ? path.sub(name, "") : "/"
  end

  def dirname
    filename.sub(/\/[^\/]+$/, "")
  end

  def url
    "#{site.url}#{filename}"
  end

  def full_url
    "#{site.full_url}#{filename}"
  end

  def initialize(attributes = {})
    saved_path = attributes.delete :saved_path
    @saved_path = saved_path unless saved_path.nil?

    is_dir = attributes.delete :is_dir
    @is_dir = is_dir.nil? ? false : is_dir
    super
  end

  class << self
    def remove_exif(binary)
      list = Magick::ImageList.new
      list.from_blob(binary)
      list.each do |image|
        case SS.config.env.image_exif_option
        when "auto_orient"
          image.auto_orient!
        when "strip"
          image.strip!
        end
      end
      list.to_blob
    rescue
      # ImageMagick doesn't able to handle all image formats. There ara some formats causing unsupported handler exception.
      # Not all image formats have exif. Some formats link svg or ico haven't exif.
      binary
    end
  end

  private

  def validate_filename
    if directory?
      errors.add :path, :invalid_filename if filename !~ /^\/?([\w\-]+\/)*[\w\-]+$/
      return
    end

    unless /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-\.]+$/.match?(filename)
      errors.add :path, :invalid_filename
      return
    end
  end

  def path_chenged?
    !saved_path || path != saved_path
  end

  def validate_scss
    return if ext != ".scss"
    return if ::File.basename(@path)[0] == "_"

    opts = Rails.application.config.sass
    load_paths = opts.load_paths[1..-1] || []
    load_paths << "#{Rails.root}/vendor/assets/stylesheets"
    load_paths << Fs::GridFs::CompassImporter.new(::File.dirname(@path)) if Fs.mode == :grid_fs

    sass = Sass::Engine.new(
      @binary.force_encoding("utf-8"),
      cache: false,
      debug_info: true,
      filename: @path,
      inline_source_maps: true,
      load_paths: load_paths,
      style: :expanded,
      syntax: :scss
    )
    @css = sass.render
  rescue Sass::SyntaxError => e
    msg = e.backtrace[0].sub(/.*?\/_\//, "")
    msg = "[#{msg}] #{e}"
    errors.add :scss, msg
  end

  def validate_coffee
    return if ext != ".coffee"
    return if ::File.basename(@path)[0] == "_"
    @js = CoffeeScript.compile @binary
  rescue => e
    errors.add :coffee, e.message
  end

  def validate_size
    return if directory?
    limit_size = SS::MaxFileSize.find_size(ext.sub('.', ''))
    return if binary.size <= limit_size
    self.errors.add :base, :too_large_file, filename: filename,
      size: ActiveSupport::NumberHelper.number_to_human_size(binary.size),
      limit: ActiveSupport::NumberHelper.number_to_human_size(limit_size)
  end

  def compile_scss
    path = @saved_path.sub(/(\.css)?\.scss$/, ".css")
    Fs.binwrite path, @css
  end

  def compile_coffee
    path = @saved_path.sub(/(\.js)?\.coffee$/, ".js")
    Fs.binwrite path, @js
  end

  class << self
    def t(*args)
      human_attribute_name *args
    end

    def file(path)
      return nil if !Fs.exists?(path) && (Fs.mode != :grid_fs)
      Uploader::File.new(path: path, saved_path: path, is_dir: Fs.directory?(path))
    end

    def find(path)
      items = []
      return items if !Fs.exists?(path) && (Fs.mode != :grid_fs)
      return items unless Fs.directory?(path)

      Fs.glob("#{path}/*").each do |f|
        items << Uploader::File.new(path: f, saved_path: f, is_dir: Fs.directory?(f))
      end
      items
    end

    def search(path, params = {})
      items = find(path)
      return items if params.blank?

      if params[:keyword].present?
        items = items.select { |item| item.basename =~ /#{::Regexp.escape(params[:keyword])}/i }
      end
      items
    end
  end
end
