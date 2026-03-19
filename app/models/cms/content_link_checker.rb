class Cms::ContentLinkChecker
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :page, :html
  attr_reader :extracted_urls, :results

  Result = Data.define(:result, :message, :redirection_count, :normalized_url) do
    def self.from(result)
      case result
      when Cms::LinkChecker::Result
        new(
          result: result.success? ? :success : :error,
          message: result.message, redirection_count: result.redirection_count,
          normalized_url: nil)
      else
        "Unsupported Type: #{result.class.name}"
      end
    end

    def self.success(redirection_count: 0, normalized_url: nil)
      new(result: :success, message: nil, redirection_count: redirection_count, normalized_url: normalized_url)
    end

    def self.nofollow(redirection_count: 0, normalized_url: nil)
      new(result: :nofollow, message: nil, redirection_count: redirection_count, normalized_url: normalized_url)
    end

    def self.skip(redirection_count: 0, normalized_url: nil)
      new(result: :skip, message: nil, redirection_count: redirection_count, normalized_url: normalized_url)
    end

    def self.error(message:, redirection_count: 0, normalized_url: nil)
      new(result: :error, message: message, redirection_count: redirection_count, normalized_url: normalized_url)
    end
  end

  def initialize(attributes = nil)
    super
    @extracted_urls = {}
    @results = {}
  end

  class << self
    def check(cur_site:, cur_user:, page:, html:)
      checker = new(cur_site: cur_site, cur_user: cur_user, page: page, html: html)
      checker.call
      checker
    end
  end

  def call
    extractor = Cms::CheckLinks::LinkExtractor.new(
      cur_site: cur_site, base_url: root_full_url, fragment: document)
    extractor.each do |link|
      next if link.href == "#"
      next if extracted_urls[link.href]

      if link.type == :broken
        extracted_urls[link.href] = link.href
        results[link.href] = Result.error(message: I18n.t("errors.messages.link_check_failed_invalid_link"))
        next
      end

      str_full_url = link.full_url.to_s
      extracted_urls[link.href] = str_full_url
      next if results[str_full_url]

      if link.rel && link.rel.include?("nofollow") || link.ss_rel && link.ss_rel.include?("nofollow")
        result = Result.nofollow
      else
        if link.href.start_with?("#")
          result = check_fragment(link.href)
        elsif link.type == :ignore
          result = Result.skip
        else
          result = Result.from(check_url(link.full_url))
        end
      end

      result = result.with(normalized_url: str_full_url)
      results[str_full_url] = result
    rescue Addressable::URI::InvalidURIError
      extracted_urls[link.href] = link.href
      results[link.href] = Result.error(message: I18n.t("errors.messages.link_check_failed_invalid_link"))
    end
  end

  private

  def root_full_url
    @root_full_url ||= page.full_url
  end

  def document
    @document ||= Nokogiri::HTML5.fragment(html)
  end

  def check_fragment(fragment)
    if document.at_css("*[id='#{fragment[1..-1]}']").present?
      Result.success
    else
      Result.error(message: I18n.t('errors.template.no_links'))
    end
  end

  def checker
    @checker ||= Cms::LinkChecker.new(cur_user: cur_user, root_url: cur_site.full_root_url)
  end

  def check_url(full_url)
    checker.check_url(full_url)
  end
end
