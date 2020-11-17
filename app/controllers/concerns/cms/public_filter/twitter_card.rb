module Cms::PublicFilter::TwitterCard
  extend ActiveSupport::Concern

  def twitter_card(key, *values)
    @twitter_cards ||= begin
      [
        [ 'twitter:card', @cur_site.twitter_card ],
        [ 'twitter:site', @cur_site.twitter_username ],
        [ 'twitter:url', ->() { @cur_item.full_url } ],
        [ 'twitter:title', ->() { @window_name } ],
        [ 'twitter:description', ->() { twitter_description } ],
        [ 'twitter:image', ->() { twitter_image_urls } ],
      ]
    end

    if values.blank?
      # getter
      ret = @twitter_cards.select { |k, v| k == key }.map do |k, v|
        if v.is_a?(Proc)
          self.instance_exec(&v)
        else
          v
        end
      end
      ret.flatten
    else
      # setter
      @twitter_cards.delete_if { |k, v| k == key }
      values.each do |value|
        @twitter_cards << [ key, value ]
      end
    end
  end

  private

  def twitter_description
    if @cur_item
      description ||= @cur_item.html.presence if @cur_item.respond_to?(:html)
      description ||= @cur_item.text.presence if @cur_item.respond_to?(:text)
      description ||= @cur_item.description.presence if @cur_item.respond_to?(:description)
      description ||= @cur_item.summary.presence if @cur_item.respond_to?(:summary)
      description ||= (@cur_item.keywords.presence || []).join(' ').presence if @cur_item.respond_to?(:keywords)
    end
    return if description.blank?

    %w(script style).each do |tag|
      description = description.gsub(/<#{tag}.+?<\/#{tag}>/mi, '')
    end
    ApplicationController.helpers.sanitize(description, tags: []).squish.truncate(200)
  end

  def twitter_image_urls
    urls = extract_image_urls
    if urls.blank?
      urls = [ @cur_site.twitter_default_image_url ] if @cur_site.twitter_default_image_url.present?
    end
    urls
  end

  def extract_image_urls
    if @cur_item
      if @cur_item.respond_to?(:thumb)
        thumb = @cur_item.thumb
      end

      if @cur_item.respond_to?(:form) && @cur_item.form
        html = @cur_item.column_values.map(&:to_html).join("\n")
      elsif @cur_item.respond_to?(:html)
        html = @cur_item.html.to_s
      end
    end

    urls = []
    if thumb.present?
      urls << thumb.full_url
    end

    if html.present?
      # extract image from html
      urls += extract_image_urls_from_html(html)
    end

    urls
  end

  def extract_image_urls_from_html(html)
    regex = /\<\s*?img\s+[^>]*\/?>/i
    urls = html.scan(regex).map do |m|
      next nil unless m =~ /src\s*=\s*(['"]?[^'"]+['"]?)/

      url = $1
      url = url[1..-1] if url.start_with?("'", '"')
      url = url[0..-2] if url.end_with?("'", '"')
      url = url.strip

      next nil unless url.start_with?("/")

      "#{@cur_site.full_root_url}#{url[1..-1]}"
    end

    urls.compact
  end
end
