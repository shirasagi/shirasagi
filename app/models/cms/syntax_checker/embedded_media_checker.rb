class Cms::SyntaxChecker::EmbeddedMediaChecker
  include Cms::SyntaxChecker::Base

  EMBEDDED_MEDIA_TAGS = [
    [ :video, '*'.freeze ].freeze,
    [ :audio, '*'.freeze ].freeze,
    [ :embed, 'src'.freeze ].freeze,
    [ :iframe, 'src'.freeze ].freeze,
    [ :object, 'data'.freeze ].freeze,
    [ :portal, 'src'.freeze ].freeze,
    [ :a, 'href'.freeze ].freeze,
  ].freeze

  MEDIA_HOSTS = %w(www.youtube.com).freeze
  MEDIA_MIME_TYPES = begin
    ::MIME::Types.select { |type| type.content_type.start_with?("audio/", "video/") }.map(&:content_type).uniq.sort.freeze
  end
  MEDIA_EXTENSIONS = begin
    ::MIME::Types.select { |type| type.content_type.start_with?("audio/", "video/") }.map(&:extensions).flatten.uniq.sort.freeze
  end

  def check(context, id, idx, raw_html, fragment)
    EMBEDDED_MEDIA_TAGS.each do |tag, attr|
      query = tag.to_s
      query += "[#{attr}]" if attr != "*"
      fragment.css(query).each do |node|
        if attr != "*"
          attr_value = node[attr]
          next if attr_value.blank? || !media_src?(attr_value)
        end

        context.errors << {
          id: id,
          idx: idx,
          code: Cms::SyntaxChecker::Base.outer_html_summary(node),
          msg: I18n.t('errors.messages.check_embedded_media'),
          detail: I18n.t('errors.messages.syntax_check_detail.check_embedded_media')
        }
      end
    end
  end

  private

  def media_src?(src)
    url = ::Addressable::URI.parse(src) rescue nil
    return false if !url

    return true if url.hostname.present? && MEDIA_HOSTS.include?(url.hostname)

    if url.scheme == "data"
      # data-url
      i = url.path.index(';')
      return false if i.nil?

      mime_type = url.path[0..i - 1]
      return MEDIA_MIME_TYPES.include?(mime_type.downcase)
    end

    ext = url.extname
    return false if ext.blank?

    ext = ext[1..-1] if ext.start_with?(".")
    ext = ext.downcase
    MEDIA_EXTENSIONS.include?(ext)
  end
end
