# ref : https://googleapis.dev/ruby/google-cloud-translate/latest/Google/Cloud.html

class Translate::Api::GoogleTranslator
  attr_reader :site, :key, :url, :count

  def initialize(site, opts = {})
    require "google/cloud"
    require "google/cloud/translate"

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

    @client = Google::Cloud.translate(credentials: @credentials)
    @parent = @client.class.location_path(@project_id, @location_id)
  end

  def request_word_limit
    limit = @site.translate_api_request_word_limit.to_i
    limit > 0 ? limit : nil
  end

  def request_word_limit_exceeded?(count)
    return false if request_word_limit.nil?
    (@site.translate_mock_api_request_word_count + count) >= request_word_limit
  end

  def translate(contents, source_language, target_language, opts = {})
    @count = 0

    count = contents.map(&:size).sum

    if request_word_limit_exceeded?(count)
      @site.request_word_limit_exceeded = true
      raise Translate::RequestLimitExceededError, "request word limit exceeded"
    end

    response = @client.translate_text(contents, target_language, @parent, source_language_code: source_language)
    translated = response.translations.map { |translation| ::CGI.unescapeHTML(translation.translated_text) }
    @count = count

    @site.translate_google_api_request_count += 1
    @site.translate_google_api_request_word_count += @count

    translated
  end
end
