class Uploader::File
  include ActiveModel::Model

  attr_accessor :path, :binary
  attr_reader :saved_path, :is_dir

  validates :path, presence: true
  validates :filename, length: { maximum: 2000 }

  validate :validate_filename
  validate :validate_exists, if: :path_chenged?
  validate :validate_scss
  validate :validate_coffee

  public
    def save
      if valid?
        begin
          if saved_path && path != saved_path #persisted AND path chenged
            if directory?
              Fs.mv saved_path, path
            else
              Fs.binwrite saved_path, binary
              Fs.mv saved_path, path
            end
          else
            if directory?
              Fs.mkdir_p path
            else
              Fs.binwrite path, binary
            end
          end
          compile_scss if @css
          compile_coffee if @js

          @saved_path = @path
          return true
        rescue => e
          errors.add :path, ":" + e.message
          return false
        end
      else
        return false
      end
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
      self.ext =~ /txt|css|scss|coffee|js|htm|html|php/
    end

    def image?
      self.content_type =~ /^image\//
    end

    def link
      return path.sub(/.*?\/_\//, "/") if Fs.mode == :grid_fs
      "/sites#{path.sub(/^#{SS::Site.root}/, '')}"
    end

    def filename
      return path.sub(/.*?\/_\//, "") if Fs.mode == :grid_fs
      path.sub(/^#{SS::Site.root}.+?\/_\//, "")
    end

    def filename=(n)
      @path = "#{path.sub(filename, '')}#{n}"
    end

    def name
      path.sub(/^.*\//, "")
    end

    def parent
      path =~ /\// ? path.sub(name, "") : "/"
    end

    def dirname
      filename.sub(/\/[^\/]+$/, "")
    end

    def initialize(attributes={})
      if attributes[:saved_path] != nil
        @saved_path = attributes[:saved_path]
        attributes.delete :saved_path
      end

      if attributes[:is_dir] != nil
        @is_dir = attributes[:is_dir]
        attributes.delete :is_dir
      else
        @is_dir = false
      end
      super
    end

  private
    def validate_filename
      if directory?
        errors.add :path, :invalid if filename !~ /^\/?([\w\-]+\/)*[\w\-]+$/
      else
        errors.add :path, :invalid if filename !~ /^\/?([\w\-]+\/)*[\w\-]+\.[\w\-\.]+$/
      end
    end

    def validate_exists
      errors.add :name, :taken if Fs.exists? path
    end

    def path_chenged?
      !saved_path || path != saved_path
    end

    def validate_scss
      return if ext != ".scss"
      opts = Rails.application.config.sass
      sass = Sass::Engine.new @binary.force_encoding("utf-8"), filename: @path,
        syntax: :scss, cache: false,
        load_paths: opts.load_paths[1..-1],
        style: :expanded,
        debug_info: true
      @css = sass.render
    rescue Sass::SyntaxError => e
      msg = e.backtrace[0].sub(/.*?\/_\//, "")
      msg = "[#{msg}] #{e}"
      errors.add :scss, msg
    end

    def validate_coffee
      return if ext != ".coffee"
      @js = CoffeeScript.compile @binary
    rescue => e
      errors.add :coffee, e.message
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
    public
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

        if Fs.directory? path
          Fs.glob("#{path}/*").each do |f|
            items << Uploader::File.new(path: f, saved_path: f, is_dir: Fs.directory?(f))
          end
        end
        items
      end
  end
end
