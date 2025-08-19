class Cms::ContentLinkChecker
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :page, :html
  attr_reader :extracted_urls, :results

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
    each_link do |link, rel, ss_rel|
      next if link == "#"
      next if extracted_urls[link]

      full_url = Addressable::URI.join(root_full_url, link).to_s
      extracted_urls[link] = full_url
      next if results[full_url]

      if rel && rel.include?("nofollow") || ss_rel && ss_rel.include?("nofollow")
        result = { code: "nofollow" }
      else
        if link.start_with?("#")
          result = check_fragment(link)
        else
          result = check_url(full_url)
        end
      end

      unless result.key?(:normalized_url)
        result[:normalized_url] = full_url
      end
      results[full_url] = result
    rescue Addressable::URI::InvalidURIError
      extracted_urls[link] = link
      results[link] = {
        code: 0, message: I18n.t("errors.messages.link_check_failed_invalid_link")
      }
    end
  end

  private

  def root_full_url
    @root_full_url ||= page.full_url
  end

  def document
    @document ||= Nokogiri::HTML5.fragment(html)
  end

  def each_link(&block)
    document.css('a[href]').each do |anchor|
      link = anchor.attr('href')
      link = link.try(:strip)
      next if link.blank?

      rel = anchor.attr('rel').presence
      ss_rel = anchor.attr('data-ss-rel').presence

      yield link, rel, ss_rel
    end
  end

  def check_fragment(fragment)
    # if document.css(fragment).present?
    if document.at_css("*[id='#{fragment[1..-1]}']").present?
      { code: 200 }
    else
      { code: 0, message: I18n.t('errors.template.no_links') }
    end
  end

  def checker
    @checker ||= Cms::LinkChecker.new(cur_user: cur_user, root_url: root_full_url)
  end

  def check_url(full_url)
    checker.check_url(full_url)
  end
end
