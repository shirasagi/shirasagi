require 'weakref'

class SS::LiquidPartDrop < Liquid::Drop
  MAX_LENGTH = 5

  class << self
    def get(site)
      find(site) || create(site)
    end

    private

    def cache
      @cache ||= []
    end

    def add_to_cache(item)
      cache.unshift(item)

      overflow = cache.length - MAX_LENGTH
      if overflow > 0
        cache.pop(overflow)
      end
    end

    def find(site)
      cache.find { |item| item.site.id == site.id }
    end

    def create(site)
      ret = new(site)
      add_to_cache(ret)
      ret
    end
  end

  attr_reader :site

  private_class_method :new
  def initialize(site)
    @site = site
    @render_locks = {}
  end

  def key?(filename)
    Cms::Part.site(@site).and_public.where(filename: normalize_filename(filename)).present? || super
  end

  def [](method_or_key)
    find_part(method_or_key) || super
  end

  def in_render(part)
    raise "Render was called multiple times in this part: #{part.filename}" if @render_locks[part.filename]

    @render_locks[part.filename] = true
    yield
  ensure
    @render_locks.delete(part.filename)
  end

  private

  def find_part(filename)
    Cms::Part.site(@site).and_public.where(filename: normalize_filename(filename)).first
  end

  def normalize_filename(filename)
    if !filename.include?(".")
      filename = "#{filename}.part.html"
    end

    filename
  end
end
