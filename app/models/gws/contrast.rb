class Gws::Contrast
  extend SS::Translation
  include SS::Document
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_contrasts', :edit

  field :name, type: String
  field :order, type: Integer
  field :state, type: String, default: 'public'
  field :text_color, type: String
  field :color, type: String
  permit_params :name, :order, :state, :text_color, :color

  validates :name, presence: true, length: { maximum: 40 }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :text_color, presence: true, if: -> { state == 'public' }
  validates :text_color, "ss/color" => true
  validates :color, presence: true, if: -> { state == 'public' }
  validates :color, "ss/color" => true

  scope :and_public, ->(_date = nil){ where state: 'public' }

  def state_options
    %w(public closed).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  class << self
    def search(params = {})
      all.search_name(params).search_keyword(params)
    end

    def search_name(params = {})
      return all if params.blank? || params[:name].blank?
      all.search_text params[:name]
    end

    def search_keyword(params = {})
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name
    end

    def restore_from_cookie(cookies, site)
      cookie_key = "gws-contrast-#{site.id}"
      return unless cookies[cookie_key].present?

      contrast_setting = JSON.parse(cookies[cookie_key]) rescue nil
      return unless contrast_setting

      contrast = Gws::Contrast.new(
        id: contrast_setting["id"],
        text_color: contrast_setting["text_color"],
        color: contrast_setting["color"]
      )

      return if SS::Color.parse(contrast.text_color).blank? || SS::Color.parse(contrast.color).blank?

      contrast
    end

    def save_in_cookie(cookies, site, contrast)
      cookie_key = "gws-contrast-#{site.id}"
      contrast_setting = {
        id: contrast.id,
        text_color: contrast.text_color,
        color: contrast.color
      }
      cookies[cookie_key] = contrast_setting.to_json
    end

    def remove_from_cookie(cookies, site)
      cookie_key = "gws-contrast-#{site.id}"
      cookies.delete(cookie_key)
    end
  end
end
