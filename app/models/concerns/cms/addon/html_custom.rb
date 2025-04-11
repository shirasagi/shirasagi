module Cms::Addon
  module HtmlCustom
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String

      permit_params :html
    end

    def html_format
      return "shirasagi" unless respond_to?(:loop_setting)
      loop_setting.try(:html_format) || "shirasagi"
    end

    def html_format_shirasagi?
      html_format == "shirasagi"
    end

    def html_format_liquid?
      html_format == "liquid"
    end
  end
end
