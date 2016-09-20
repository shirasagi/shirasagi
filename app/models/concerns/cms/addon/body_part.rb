module Cms::Addon
  module BodyPart
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :body_parts, type: Array, default: []
      permit_params body_parts: []
    end

    private
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
