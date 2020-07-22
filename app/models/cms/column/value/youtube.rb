class Cms::Column::Value::Youtube < Cms::Column::Value::Base
  field :url, type: String
  field :youtube_id, type: String
  field :width, type: Integer
  field :height, type: Integer
  field :auto_width, type: String, default: -> { "disabled" }

  permit_values :url, :youtube_id, :width, :height, :auto_width

  before_validation :set_youtube_id, unless: ->{ @new_clone }

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
        if uri.query.present?
          value = URI::decode_www_form(uri.query).find { |k, _| k == "v" }
          return value ? value[1] : nil
        end

        if uri.path.start_with?("/embed/")
          return uri.path[7..-1].sub(/\/.*$/, "")
        end
      end

      # other
      nil
    end
  end

  def youtube_url
    youtube_id.present? ? "https://youtu.be/#{youtube_id}" : nil
  end

  def youtube_embed_url
    youtube_id.present? ? "https://www.youtube.com/embed/#{youtube_id}" : nil
  end

  def youtube_iframe
    return if youtube_id.blank?

    options = {
      src: youtube_embed_url,
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

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:url)
        self.url = value
      when self.class.t(:youtube_id)
        self.youtube_id = value
      when self.class.t(:width)
        self.width = value
      when self.class.t(:height)
        self.height = value
      when self.class.t(:auto_width)
        self.auto_width = value.present? ? I18n.t("cms.column_youtube_auto_width").invert[value] : nil
      end
    end
  end

  private

  def set_youtube_id
    self.youtube_id = self.class.get_youtube_id(url)
  end

  def validate_value
    return if column.blank?

    if column.required? && youtube_id.blank?
      self.errors.add(:url, :blank)
    end

    if url.present? && youtube_id.blank?
      self.errors.add(:url, :youtube_id_can_not_get)
    end
  end

  def to_default_html
    return '' if youtube_id.blank?

    if auto_width == "enabled"
      ApplicationController.helpers.content_tag(:div, class: "youtube-auto-width youtube-embed-wrapper") do
        youtube_iframe
      end
    else
      youtube_iframe
    end
  end
end
