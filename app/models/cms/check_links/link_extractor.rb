# リンク抽出
class Cms::CheckLinks::LinkExtractor
  include ActiveModel::Model

  attr_accessor :cur_site, :base_url, :html

  def call
    return SS::EMPTY_ARRAY if html.blank?

    ret = []
    layout_yield = 0
    document.traverse do |node|
      if node.comment?
        comment_text = node.text.strip
        if comment_text == "layout_yield"
          layout_yield += 1
        elsif comment_text == "/layout_yield"
          layout_yield -= 1
        end

        next
      end
      next unless node.element?

      extracted_href = node["href"]
      next if extracted_href.blank? || extracted_href[0] == "#"

      extracted_full_url = Addressable::URI.join(base_url, extracted_href) rescue nil
      next unless extracted_full_url

      extracted_full_url = extracted_full_url.normalize
      if ignore_urls.match?(extracted_full_url)
        type = :ignore
      elsif layout_yield > 0
        type = :inner_yield
      else
        type = :outer_yield
      end
      rel = node["rel"].presence
      ss_rel = node["data-ss-rel"].presence

      link = Cms::CheckLinks::Link.new(
        full_url: extracted_full_url, href: extracted_href, line: node.line, type: type, rel: rel, ss_rel: ss_rel)
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

  def document
    @document ||= Nokogiri::HTML5.fragment(normalized_html)
  end
end
