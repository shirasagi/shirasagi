require "rss/maker"
module Cms::FeedFilter
  extend ActiveSupport::Concern

  private

  def _render_rss(node, items)
    RSS::Maker.make("2.0") do |rss|
      summary = nil
      %w(description name).each do |m|
        summary = node.send(m) if summary.blank? && node.respond_to?(m)
      end

      rss.channel.title       = sanitize("#{node.name} - #{node.site.name}")
      rss.channel.link        = node.full_url
      rss.channel.description = sanitize(summary)
      rss.channel.about       = node.full_url
      rss.channel.language    = "ja"
      # rss.channel.pubDate     = date.to_s

      items.each do |item|
        item = item.becomes_with_route rescue item
        date = nil
        %w(released updated created).each { |m| date ||= item.send(m) if item.respond_to?(m) }

        summary = nil
        # %w(summary description).each {|m| summary ||= item.send(m) if item.respond_to?(m) }

        rss.items.new_item do |entry|
          title = item.try(:index_name).presence || item.name
          title = sanitize(title)

          entry.title       = title
          entry.link        = item.full_url
          entry.description = sanitize(summary) if summary.present?
          entry.pubDate     = date.to_s if date.present?
        end
      end
    end
  end

  def render_rss(node, items)
    rss = _render_rss(node, items)
    render xml: rss.to_xml, content_type: "application/rss+xml"
  end

  def sanitize(html_or_text)
    view_context.sanitize html_or_text
  end
end
