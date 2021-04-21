class Translate::RequestBuffer
  attr_reader :translated, :caches
  attr_reader :source, :target
  attr_reader :request_count, :request_word_count

  def initialize(site, source, target, opts = {})
    @site = site
    @source = source
    @target = target

    initialize_api
    reset_result
    reset_buffer

    @array_size_limit = opts[:array_size_limit] if opts[:array_size_limit]
    @text_size_limit = opts[:text_size_limit] if opts[:text_size_limit]
    @contents_size_limit = opts[:contents_size_limit] if opts[:contents_size_limit]
    @interval = opts[:interval] if opts[:interval]
  end

  def initialize_api
    case @site.translate_api
    when "microsoft_translator_text"
      @api = Translate::Api::MicrosoftTranslator.new(@site)
    when "google_translation"
      @api = Translate::Api::GoogleTranslator.new(@site)
    when "mock"
      @api = Translate::Api::MockTranslator.new(@site)
    else
      raise "translate : unsupported api"
    end

    config = SS.config.translate[@site.translate_api]
    @array_size_limit = config["array_size_limit"]
    @text_size_limit = config["text_size_limit"]
    @contents_size_limit = config["contents_size_limit"]
    @interval = config["interval"]
  end

  def reset_buffer
    @caches = []
    @requests = []
    @contents = []
    @contents_size = 0
  end

  def reset_result
    @translated = {}
    @request_count = 0
    @request_word_count = 0
  end

  def requests
    @contents.present? ? (@requests + [@contents]) : @requests
  end

  def find_cache(text, key)
    api = @site.translate_api
    hexdigest = Translate::TextCache.hexdigest(api, @source.code, @target.code, text)
    cond = { site_id: @site.id, hexdigest: hexdigest }
    item = Translate::TextCache.find_or_create_by(cond) do |item|
      item.api = api
      item.update_state = "auto"
      item.source = @source.code
      item.target = @target.code
      item.original_text = text
    end

    if item.original_text != text
      raise "translate : not unique hexdigest #{hexdigest}"
    end

    item.key = key
    item
  end

  def push(text, key)
    text = text.to_s.strip
    texts = text.scan(/.{1,#{@text_size_limit}}/)
    caches = texts.map { |text| find_cache(text, key) }

    cache_ids = []
    caches.each do |cache|
      @caches << cache
      next if cache.text.present?
      next if cache_ids.include?(cache.id.to_s)

      cache_ids << cache.id.to_s
      size = cache.original_text.size

      if @contents.size >= @array_size_limit
        @requests << @contents
        @contents = []
        @contents_size = 0
      elsif (@contents_size + size) > @contents_size_limit
        @requests << @contents
        @contents = []
        @contents_size = 0
      end

      @contents_size += size
      @contents << cache
    end
  end

  def translate
    reset_result

    requests.each do |contents|
      texts = contents.map { |cache| cache.original_text }
      translated = texts
      error = false

      begin
        translated = @api.translate(texts, source.api_code, target.api_code, site: @site)
      rescue => e
        Rails.logger.error("#{@site.label(:translate_api)} : #{e.class} (#{e.message})")
        error = true
      end

      contents.each_with_index do |cache, i|
        cache.text = translated[i]
        cache.save! if !error
      end

      sleep @interval
    end

    @site.update!

    @caches.each do |cache|
      if cache.text.blank?
        cache.reload
      end

      @translated[cache.key] ||= []
      @translated[cache.key] << cache
    end

    reset_buffer

    @translated
  end
end
