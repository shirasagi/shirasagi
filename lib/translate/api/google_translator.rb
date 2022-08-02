# ref : https://googleapis.dev/ruby/google-cloud-translate/latest/Google/Cloud.html
require "google/cloud/translate/v2"

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

    @client = Google::Cloud::Translate::V2.new(project_id: @project_id, credentials: @credentials)
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

    translations = @client.translate(*contents, to: target_language, from: source_language)
    translated = translations.map { |translation| ::CGI.unescapeHTML(translation.text) }
    @count = count

    @site.translate_google_api_request_count += 1
    @site.translate_google_api_request_word_count += @count

    translated
  end
end
