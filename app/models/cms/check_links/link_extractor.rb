# リンク抽出
class Cms::CheckLinks::LinkExtractor
  include ActiveModel::Model
  include Enumerable

  HYPERLINK_ELEMENT_TAG_NAMES = Set.new(%w(a area)).freeze
  IMAGE_ELEMENT_TAG_NAMES = Set.new(%w(img audio video source iframe)).freeze

  attr_accessor :cur_site, :base_url, :html
  attr_writer :fragment

  def each
    return SS::EMPTY_ARRAY if fragment.blank?

    traverse_nodes do |node, layout_yield|
      if hyperlink_element?(node)
        link = create_link_from_hyperlink(node, layout_yield)
      elsif image_element?(node)
        link = create_link_from_image(node, layout_yield)
      end
      next unless link

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

  def hyperlink_element?(node)
    return false if node["href"].blank?
    HYPERLINK_ELEMENT_TAG_NAMES.include?(node.name)
  end

  def image_element?(node)
    return false if node["src"].blank?
    IMAGE_ELEMENT_TAG_NAMES.include?(node.name)
  end

  def create_link_from_hyperlink(node, layout_yield)
    href = node["href"]
    rel = node["rel"].presence
    ss_rel = node["data-ss-rel"].presence
    return if href.blank? || href == "#"

    extracted_full_url = Addressable::URI.join(base_url, href) rescue nil
    extracted_full_url = extracted_full_url.normalize rescue nil if extracted_full_url
    unless extracted_full_url
      link = Cms::CheckLinks::Link.new(
        full_url: nil, href: href, line: node.line, type: :broken, rel: rel, ss_rel: ss_rel)
      return link
    end

    if ignore_urls.match?(extracted_full_url)
      type = :ignore
    elsif layout_yield > 0
      type = :inner_yield
    else
      type = :outer_yield
    end

    Cms::CheckLinks::Link.new(
      full_url: extracted_full_url, href: href, line: node.line, type: type, rel: rel, ss_rel: ss_rel)
  end

  def create_link_from_image(node, layout_yield)
    href = node["src"]
    # rel は global attributes ではないので <img> タグなどでは使用できない
    # <img> タグなどでは data-ss-rel を利用すること
    ss_rel = node["data-ss-rel"].presence
    return if href.blank? || href == "#"

    extracted_full_url = Addressable::URI.join(base_url, href) rescue nil
    extracted_full_url = extracted_full_url.normalize rescue nil if extracted_full_url
    unless extracted_full_url
      link = Cms::CheckLinks::Link.new(
        full_url: nil, href: href, line: node.line, type: :broken, rel: nil, ss_rel: ss_rel)
      return link
    end

    if ignore_urls.match?(extracted_full_url)
      type = :ignore
    elsif layout_yield > 0
      type = :inner_yield
    else
      type = :outer_yield
    end

    Cms::CheckLinks::Link.new(
      full_url: extracted_full_url, href: href, line: node.line, type: type, rel: nil, ss_rel: ss_rel)
  end
end
