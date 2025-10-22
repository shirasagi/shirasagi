class Cms::Column::Value::Youtube < Cms::Column::Value::Base
  field :url, type: String
  field :youtube_id, type: String
  field :width, type: Integer
  field :height, type: Integer
  field :auto_width, type: String, default: -> { "disabled" }
  field :title, type: String, metadata: { syntax_check: { value: true, presence: true } }

  permit_values :url, :youtube_id, :width, :height, :auto_width, :title

  before_validation :set_youtube_id

  liquidize do
    export :youtube_id
    export :width
    export :height
    export :auto_width
    export :title
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
      allowfullscreen: "allowfullscreen",
      title: title.presence || I18n.t("mongoid.attributes.cms/column/value/youtube.generic_title")
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
      when self.class.t(:title)
        self.title = value
      when self.class.t(:width)
        self.width = value
      when self.class.t(:height)
        self.height = value
      when self.class.t(:auto_width)
        self.auto_width = value.present? ? I18n.t("cms.column_youtube_auto_width").invert[value] : nil
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("url")}: #{url}" if url.present?
    h << "#{t("title")}: #{title}" if title.present?
    h << "#{t("width")}: #{width}" if width.present?
    h << "#{t("height")}: #{height}" if height.present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    self.url = value.presence
  end

  def export_csv_cell
    url
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [url, youtube_id]).present?
  end

  def fetch_youtube_title
    return if youtube_id.blank? || title.present?

    uri = URI.parse("https://www.youtube.com/oembed")
    uri.query = URI.encode_www_form({url: "https://www.youtube.com/watch?v=#{youtube_id}", format: "json"})

    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      raise "YouTube oEmbed API request failed for video: #{youtube_id}, status: #{response.code}"
    end

    data = JSON.parse(response.body)
    unless data["title"].present?
      raise "YouTube oEmbed API returned no title for video: #{youtube_id}"
    end

    self.title = data["title"]
  end

  private

  def set_youtube_id
    self.youtube_id = self.class.get_youtube_id(url)
  end

  def validate_value
    return if column.blank? || skip_required?

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

  class << self
    def form_example_layout
      h = []
      h << %({% if value.youtube_id %})
      h << %(  <iframe src="https://www.youtube.com/embed/{{ value.youtube_id }}")
      h << %(    title="{{ value.title }}" )
      h << %(    width="{{ value.width }}" )
      h << %(    height="{{ value.height }}")
      h << %(    frameborder="0")
      h << %(    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture")
      h << %(    allowfullscreen="allowfullscreen"></iframe>)
      h << %({% endif %})
      h.join("\n")
    end
  end
end
