# ref:
# - https://cloud.google.com/translate/docs/reference/rest/v2/translate
# - https://googleapis.dev/ruby/google-cloud-translate/latest/Google/Cloud.html
require 'googleauth'
require 'google/apis/translate_v2'

class Translate::Api::GoogleTranslator
  attr_reader :site, :key, :url, :count

  def initialize(site, opts = {})
    @site = site
    @count = 0

    @project_id = SS.config.translate.google_translation["project_id"]
    @credentials = SS.config.translate.google_translation["credentials"]
    @location_id = "global"

    if site.translate_google_api_project_id.present?
      @project_id = site.translate_google_api_project_id
    end

    if site.translate_google_api_credential_file.present?
      @credentials = site.translate_google_api_credential_file.path
    end

    @project_id = opts[:project_id] if opts[:project_id]
    @credentials = opts[:credentials] if opts[:credentials]
    @location_id = opts[:location_id] if opts[:location_id]

    authorization = ::File.open(@credentials) do |f|
      Google::Auth::DefaultCredentials.make_creds(json_key_io: f, scope: [ Google::Apis::TranslateV2::AUTH_CLOUD_TRANSLATION ])
    end
    authorization.fetch_access_token!

    client = Google::Apis::TranslateV2::TranslateService.new
    client.authorization = authorization

    @client = client
  end

  def request_word_limit
    limit = @site.translate_api_request_word_limit.to_i
    limit > 0 ? limit : nil
  end

  def request_word_limit_exceeded?(count)
    return false if request_word_limit.nil?
    (@site.translate_google_api_request_word_count + count) >= request_word_limit
  end

  def translate(contents, source_language, target_language, site:)
    @count = 0

    count = contents.sum(&:size)

    if request_word_limit_exceeded?(count)
      @site.request_word_limit_exceeded = true
      raise Translate::RequestLimitExceededError, "request word limit exceeded"
    end

    request = Google::Apis::TranslateV2::TranslateTextRequest.new(
      q: contents, target: target_language, source: source_language, format: "text", model: "nmt"
    )
    response = @client.translate_translation_text(request)
    translated = response.translations.map { |translation| ::CGI.unescapeHTML(translation.translated_text) }
    @count = count

    @site.translate_google_api_request_count += 1
    @site.translate_google_api_request_word_count += @count

    translated
  end
end
