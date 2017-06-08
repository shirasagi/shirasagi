module Cms::Addon
  module BodyPart
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :body_parts, type: Array, default: []
      field :contains_urls, type: Array, default: [], overwrite: true
      permit_params body_parts: []

      before_validation :set_parts_contains_urls
    end

    private
    def set_parts_contains_urls
      return unless self.try(:body_layout)
      return if body_parts.blank?

      self.contains_urls = []
      body_parts.each do |h|
        self.contains_urls += h.scan(/(?:href|src)="(.*?)"/).flatten
      end
      self.contains_urls.uniq!
    end

    # override Cms::Addon::Body#template_variable_handler_img_src
    def template_variable_handler_img_src(name, issuer)
      if body_layout.blank?
        return super
      end

      body_parts.each do |html|
        img_source = extract_img_src(html)
        return img_source if img_source
      end

      default_img_src
    end
  end
end
