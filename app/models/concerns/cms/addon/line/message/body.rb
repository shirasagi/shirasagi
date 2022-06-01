module Cms::Addon
  module Line::Message::Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :templates, class_name: "Cms::Line::Template::Base", dependent: :destroy, inverse_of: :message
    end

    def line_messages
      templates.order_by(order: 1).map(&:body)
    end

    module ClassMethods
      def max_templates
        5.freeze
      end
    end
  end
end
