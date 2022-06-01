class Cms::Line::Template::Page < Cms::Line::Template::Base
  include Cms::Addon::Line::Template::Page

  field :title, type: String
  field :summary, type: String
  field :thumb_state, type: String, default: "none"
  permit_params :title, :summary, :thumb_state

  validates :title, presence: true, length: { maximum: 80 }
  validates :summary, presence: true, length: { maximum: 400 }
  validate :validate_page

  def type
    "page"
  end

  def balloon_html
    h = []
    query = "?_=#{Time.zone.now.to_i}"
    h << '<div class="talk-balloon">'

    if page.blank?
      h << '<div class="error">'
      h << '※ページが削除されています。<br>このメッセージは配信されません。'
      h << '</div>'
      return h.join
    end

    if !page.public?
      h << '<div class="error"">'
      h << "※ページが非公開です。<br>配信時点に非公開の場合、このメッセージは配信されません。"
      h << '</div>'
    end

    h << '<div class="message-type page">'
    if thumb_image_url
      h << "<div class=\"img-warp\"><img src=\"#{thumb_image_url}#{query}\"></div>"
    end
    h << "<div class=\"title\">#{title}</div>"
    h << "<div class=\"summary\">#{ApplicationController.helpers.br(summary)}</div>"
    h << "<div class=\"footer\"><a href=\"#{page.full_url}\">#{I18n.t("cms.visit_article")}</a></div>"
    h << '</div>'
    h << '</div>'
    h.join
  end

  def body
    raise "page deleted!" if page.blank?
    raise "page not published!" if !page.public?
    Cms::LineUtils.flex_carousel_template(title, page) do |item, opts|
      opts[:name] = title
      opts[:text] = summary
      opts[:image_url] = thumb_image_full_url
      opts[:action] = {
        type: "uri",
        label: I18n.t("cms.visit_article"),
        uri: item.full_url
      }
    end
  end

  def thumb_image_full_url
    return if page.blank?
    @_thumb_image_full_url ||= begin
      if thumb_state == "thumb_carousel"
        page.thumb.try(:full_url)
      elsif thumb_state == "body_carousel"
        page.try(:first_img_full_url)
      else
        nil
      end
    end
  end

  def thumb_image_url
    return if thumb_image_full_url.blank?
    @_thumb_image_url ||= begin
      site_url = site.full_url.delete_suffix("/")
      thumb_image_full_url.delete_prefix(site_url)
    end
  end

  def thumb_state_options
    I18n.t("cms.options.line_template_thumb_state").map { |k, v| [v, k] }
  end

  def new_clone
    item = super
    item.title = title
    item.summary = summary
    item.thumb_state = thumb_state
    item.page = page
    item
  end

  private

  def validate_page
    if page.blank?
      errors.add :page_id, :blank
      return
    end

    if thumb_state == "thumb_carousel" && page.thumb.blank?
      errors.add :thumb_state, ": ページにサムネイル画像が設定されていません。"
    end
  end
end
