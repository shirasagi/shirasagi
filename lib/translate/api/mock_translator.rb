class Translate::Api::MockTranslator
  attr_reader :site, :count

  def initialize(site, opts = {})
    @site = site
    @count = 0
  end

  def translate(contents, source, target, opts = {})
    translated = contents.map { |content| "[#{target}:" + content + "]" }
    @count = contents.map(&:size).sum

    site = opts[:site]
    if site
      site.translate_mock_api_request_count += 1
      site.translate_mock_api_request_word_count += @count
    end

    translated
  end
end
