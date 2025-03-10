class Translate::JsonConverter::ChatBot

  attr_accessor :converter, :json, :translate_url

  def initialize(converter, json, translate_url)
    @converter = converter
    @json = ActiveSupport::JSON.decode(json)
    @translate_url = translate_url
  end

  def convert
    results = @json["results"]
    results.each do |result|
      response = result["response"]
      suggests = result["suggests"]
      question = result["question"]
      search_url = result["siteSearchUrl"]

      if response.present?
        result["response"] = converter.convert(response)
      end
      if suggests.present?
        result["suggests"] = suggests.map do |suggest|
          { text: converter.convert(suggest["text"]), value: suggest["text"] }
        end
      end
      if question.present?
        result["question"] = converter.convert(question)
      end
      if search_url.present?
        result["siteSearchUrl"] = ::File.join(@translate_url, search_url)
      end
    end
    if @json["chatSuccess"].present?
      @json["chatSuccess"] = converter.convert(@json["chatSuccess"])
    end
    if @json["chatRetry"].present?
      @json["chatRetry"] = converter.convert(@json["chatRetry"])
    end
    if @json["siteSearchText"].present?
      @json["siteSearchText"] = converter.convert(@json["siteSearchText"])
    end
    ActiveSupport::JSON.encode(json)
  end
end
