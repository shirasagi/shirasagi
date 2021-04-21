class Translate::Api::MockTranslator
  attr_reader :site, :count

  def initialize(site, opts = {})
    @site = site
    @count = 0
    @processor = SS.config.translate.mock["processor"]
    @processor = opts[:processor] if opts[:processor]
  end

  def request_word_limit
    limit = @site.translate_api_request_word_limit.to_i
    limit > 0 ? limit : nil
  end

  def request_word_limit_exceeded?(count)
    return false if request_word_limit.nil?
    (@site.translate_mock_api_request_word_count + count) >= request_word_limit
  end

  def translate(contents, source, target, opts = {})
    count = contents.map(&:size).sum

    if request_word_limit_exceeded?(count)
      @site.request_word_limit_exceeded = true
      raise Translate::RequestLimitExceededError, "request word limit exceeded"
    end

    if @processor == "loopback"
      translated = contents.dup
    else
      translated = contents.map { |content| "[#{target}:" + content + "]" }
    end

    @count = count
    @site.translate_mock_api_request_count += 1
    @site.translate_mock_api_request_word_count += @count

    translated
  end
end
