module TranslateSupport
  module_function

  def self.extended(obj)
    obj.class_eval do
      delegate :translate_requests, :install_google_stubs, to: ::TranslateSupport
    end

    obj.after(:example) do
      ::TranslateSupport.translate_requests.clear
    end
  end

  def translate_requests
    @requests ||= []
  end

  def install_google_stubs
    WebMock.stub_request(:any, "https://www.googleapis.com/oauth2/v4/token").to_return do |request|
      TranslateSupport.translate_requests << request

      response = {
        access_token: unique_id,
        expires_in: 3920,
        token_type: "Bearer",
        scope: "https://www.googleapis.com/auth/cloud-translation",
        refresh_token: unique_id
      }
      { status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
    WebMock.stub_request(:any, "https://translation.googleapis.com/language/translate/v2").to_return do |request|
      TranslateSupport.translate_requests << request

      body = JSON.parse(request.body)
      translations = body["q"].map do |text|
        { "translatedText" => "[#{body["target"]}:#{text}]", "model" => "nmt" }
      end
      response = { "data" => { "translations" => translations } }
      { status: 200, body: response.to_json, headers: {'Content-Type' => 'application/json'} }
    end
  end
end

RSpec.configuration.extend(TranslateSupport, translate: true)
