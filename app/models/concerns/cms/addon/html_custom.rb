module Cms::Addon
  module HtmlCustom
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html_format, type: String
      field :html, type: String

      permit_params :html_format, :html

      validates :html_format, inclusion: { in: %w(shirasagi liquid), allow_blank: true }
    end

    def html_format_options
      use_html_format.map do |v|
        [ I18n.t("cms.options.loop_format.#{v}"), v ]
      end
    end

    def html_format_shirasagi?
      html_format == "shirasagi"
    end

    def html_format_liquid?
      html_format == "liquid"
    end

    def use_html_format
      %w(shirasagi liquid)
    end

    def html_format_changed?
      changed_attributes.key?("html_format")
    end
  end
end
