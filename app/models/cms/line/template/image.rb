class Cms::Line::Template::Image < Cms::Line::Template::Base
  include Cms::Addon::Line::Template::Image

  validate :validate_image

  def type
    "image"
  end

  def balloon_html
    query = "?_=#{Time.zone.now.to_i}"

    h = []
    h << '<div class="talk-balloon">'
    h << "<div class=\"img-warp\"><img src=\"#{image.url}#{query}\"></div>"
    h << '</div>'
    h.join
  end

  def body
    raise "image blank!" if image.blank?
    {
      type: "image",
      originalContentUrl: image.full_url,
      previewImageUrl: image.full_url
    }
  end

  def new_clone
    item = super
    if image
      item.image = image.copy
      item.image.state = "closed"
    end
    item
  end

  private

  def validate_image
    if image.blank?
      errors.add :image_id, :blank
      return
    end

    if image.extname !~ /^(png|jpg|jpeg)$/i
      errors.add :image_id, "はJPEG形式またはPNG形式で登録してください。"
    end
  end
end
