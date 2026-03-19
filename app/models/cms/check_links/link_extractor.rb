# リンク抽出
class Cms::CheckLinks::LinkExtractor
  include ActiveModel::Model

  attr_accessor :cur_site, :base_url, :html

  def call
    return SS::EMPTY_ARRAY if html.blank?

    ret = []

    # scan layout_yield offset
    normalized_html.scan(/<!-- layout_yield -->(.*?)<!-- \/layout_yield -->/m)
    yield_start, yield_end = Regexp.last_match.offset(0) if Regexp.last_match
    yield_start ||= normalized_html.size
    yield_end ||= 0

    # remove href in comment
    normalized_html.gsub!(/<!--.*?-->/m) { |m| " " * m.size }

    normalized_html.scan(/\shref="([^"]+)"/i) do |m|
      offset = Regexp.last_match.offset(0)
      href_start, href_end = offset
      inner_yield = (href_start > yield_start && href_end < yield_end)

      extracted_href = m[0]
      next if extracted_href[0] == "#"

      extracted_full_url = Addressable::URI.join(base_url, extracted_href) rescue nil
      next unless extracted_full_url

      extracted_full_url = extracted_full_url.normalize
      next if ignore_urls.match?(extracted_full_url)

      link = Cms::CheckLinks::Link.new(
        full_url: extracted_full_url, href: extracted_href, offset: offset, inner_yield: inner_yield)
      ret << link
    end

    ret
  rescue => e
    Rails.logger.error { e.message }
    ret
  end

  private

  def ignore_urls
    @_ignore_urls ||= Cms::CheckLinks::IgnoreUrlMatcher.new(cur_site: cur_site)
  end

  def normalized_html
    @normalized_html ||= NKF.nkf("-w", html)
  end
end
