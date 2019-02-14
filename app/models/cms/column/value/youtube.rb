class Cms::Column::Value::Youtube < Cms::Column::Value::Base
  field :url, type: String
  field :youtube_id, type: String
  field :width, type: Integer
  field :height, type: Integer
  field :auto_width, type: String, default: -> { "disabled" }
  field :iframe, type: String

  permit_values :url, :width, :height, :auto_width, :iframe, :youtube_id

  before_save :set_iframe

  liquidize do
    export :url
    export :youtube_id
    export :width
    export :height
    export :auto_width
    export :iframe
  end

  private

  def set_iframe
    self.youtube_id = get_youtube_id
    return if self.youtube_id.blank?
    self.iframe = ApplicationController.helpers.content_tag(:iframe, nil,
      {
        src: "https://www.youtube.com/embed/#{self.youtube_id}",
        width: width,
        height: height,
        frameborder: "0",
        allow: "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture",
        allowfullscreen: "allowfullscreen"
      }
    ).to_s
  end

  def get_youtube_id
    uri = URI::parse(url)

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

  def validate_value
    return if column.blank?

    if column.required? && url.blank?
      self.errors.add(:url, :blank)
    end

    return if self.url.blank?

    youtube_id = get_youtube_id
    if youtube_id.blank?
      self.errors.add(:url, :youtube_id_can_not_get)
    end

    if column.max_length.present? && column.max_length > 0
      if url.length > column.max_length
        self.errors.add(:url, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    return '' if url.blank?
    return '' if iframe.blank?

    if auto_width == "enabled"
      ApplicationController.helpers.content_tag(:div, class: "youtube-auto-width youtube-embed-wrapper") do
        iframe.try(:html_safe)
      end
    else
      iframe.try(:html_safe)
    end
  end
end
