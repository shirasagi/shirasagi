class Cms::Column::Value::Youtube < Cms::Column::Value::Base
  # field :url, type: String
  attr_accessor :url
  field :youtube_id, type: String
  field :width, type: Integer
  field :height, type: Integer
  field :auto_width, type: String, default: -> { "disabled" }
  # field :iframe, type: String

  permit_values :url, :width, :height, :auto_width, :iframe, :youtube_id

  before_validation :set_youtube_id

  liquidize do
    export :youtube_id
    export :width
    export :height
    export :auto_width
  end

  class << self
    def get_youtube_id(url)
      return if url.blank?

      uri = URI::parse(url) rescue nil
      return if uri.blank? || uri.host.blank?

      if uri.host == "youtu.be"
        return uri.path[1..-1]
      end

      if uri.host.end_with?(".youtube.com")
        return if uri.query.blank?

        value = URI::decode_www_form(uri.query).find { |k, _| k == "v" }
        return value ? value[1] : nil
      end

      # other
      nil
    end
  end

  def iframe
    return if youtube_id.blank?

    options = {
      src: "https://www.youtube.com/embed/#{youtube_id}",
      frameborder: "0",
      allow: "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture",
      allowfullscreen: "allowfullscreen"
    }

    if auto_width != "enabled"
      options[:width] = width
      options[:height] = height
    end

    ApplicationController.helpers.content_tag(:iframe, nil, options)
  end

  private

  def set_youtube_id
    self.youtube_id = self.class.get_youtube_id(url)
  end

  def validate_value
    return if column.blank?

    if column.required? && youtube_id.blank?
      self.errors.add(:youtube_id, :blank)
    end

    if url.present? && youtube_id.blank?
      self.errors.add(:url, :youtube_id_can_not_get)
    end
  end

  def to_default_html
    return '' if youtube_id.blank?

    if auto_width == "enabled"
      ApplicationController.helpers.content_tag(:div, class: "youtube-auto-width youtube-embed-wrapper") do
        iframe.try(:html_safe)
      end
    else
      iframe.try(:html_safe)
    end
  end
end
