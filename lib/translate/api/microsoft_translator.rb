# ref : https://github.com/MicrosoftTranslator/Text-Translation-API-V3-Ruby/blob/master/Translate.rb

class Translate::Api::MicrosoftTranslator
  attr_reader :site, :key, :url, :count, :metered_usage

  def initialize(site, opts = {})
    @site = site
    @count = 0
    @metered_usage = 0

    @key = SS.config.translate.microsoft_translator_text["key"]
    @url = SS.config.translate.microsoft_translator_text["url"]
    if @site.translate_microsoft_api_key.present?
      @key = @site.translate_microsoft_api_key
    end

    @key = opts[:key] if opts[:key]
    @url = opts[:url] if opts[:url]
  end

  def request_word_limit
    limit = @site.translate_api_request_word_limit.to_i
    limit > 0 ? limit : nil
  end

  def request_word_limit_exceeded?(count)
    return false if request_word_limit.nil?
    (@site.translate_mock_api_request_word_count + count) >= request_word_limit
  end

  def translate(texts, from, to, opts = {})
    @count = 0
    @metered_usage = 0

    count = texts.map(&:size).sum
    uri = URI(@url + "&from=#{from}&to=#{to}")
    content = texts.map { |text| { "Text" => text } }.to_json

    if request_word_limit_exceeded?(count)
      @site.request_word_limit_exceeded = true
      raise Translate::RequestLimitExceededError, "request word limit exceeded"
    end

    request = Net::HTTP::Post.new(uri)
    request['Content-type'] = 'application/json'
    request['Content-length'] = content.length
    request['Ocp-Apim-Subscription-Key'] = @key
    request['X-ClientTraceId'] = SecureRandom.uuid
    request.body = content

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
      http.request(request)
    end

    result = response.body.force_encoding("utf-8")
    json = JSON.parse(result)

    if response["x-metered-usage"].present?
      @metered_usage = response["x-metered-usage"].to_i
    end

    if response.code == "200"
      translated = json.map { |item| ::CGI.unescapeHTML(item["translations"][0]["text"]) }
      @count = count
    else
      raise ApiError, response.body.to_s
    end

    @site.translate_microsoft_api_request_count += 1
    @site.translate_microsoft_api_request_metered_usage += @metered_usage
    @site.translate_microsoft_api_request_word_count += @count

    translated
  end

  class ApiError < StandardError
  end
end
