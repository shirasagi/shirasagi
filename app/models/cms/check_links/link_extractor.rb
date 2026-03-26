# リンク抽出
class Cms::CheckLinks::LinkExtractor
  include ActiveModel::Model
  include Enumerable

  attr_accessor :cur_site, :base_url, :html
  attr_writer :fragment

  def each
    return SS::EMPTY_ARRAY if fragment.blank?

    traverse_nodes do |node, layout_yield|
      href = node["href"]
      rel = node["rel"].presence
      ss_rel = node["data-ss-rel"].presence
      next if href.blank? || href == "#"

      extracted_full_url = Addressable::URI.join(base_url, href) rescue nil
      extracted_full_url = extracted_full_url.normalize rescue nil if extracted_full_url
      unless extracted_full_url
        link = Cms::CheckLinks::Link.new(
          full_url: nil, href: href, line: node.line, type: :broken, rel: rel, ss_rel: ss_rel)
        yield link
        next
      end

      if ignore_urls.match?(extracted_full_url)
        type = :ignore
      elsif layout_yield > 0
        type = :inner_yield
      else
        type = :outer_yield
      end

      link = Cms::CheckLinks::Link.new(
        full_url: extracted_full_url, href: href, line: node.line, type: type, rel: rel, ss_rel: ss_rel)
      yield link
    end
  rescue => e
    Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  private

  def ignore_urls
    @ignore_urls ||= Cms::CheckLinks::IgnoreUrlMatcher.new(cur_site: cur_site)
  end

  def fragment
    @fragment ||= begin
      if html.present?
        Nokogiri::HTML5.fragment(NKF.nkf("-w", html))
      end
    end
  end

  def traverse_nodes(&block)
    layout_yield = 0

    fragment.traverse do |node|
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

      yield node, layout_yield
    end
  end
end
