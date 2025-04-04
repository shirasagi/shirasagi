module Cms::Addon
  module Html
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      field :html_format, type: String
      field :html_format_options, type: Array, default: %w[shirasagi]

      permit_params :html, :html_format

      validates :html_format, inclusion: { in: %w(shirasagi liquid), allow_blank: true }
    end

    def html_format_options
      self.class.use_html_format.map do |v|
        [ I18n.t("cms.options.loop_format.#{v}"), v ]
      end
    end

    def html_format_shirasagi?
      html_format == "shirasagi"
    end

    def html_format_liquid?
      html_format == "liquid"
    end

    module ClassMethods
      def use_html_format
        %w(shirasagi liquid)
      end
    end
  end
end
