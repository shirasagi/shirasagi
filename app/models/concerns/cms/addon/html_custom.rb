module Cms::Addon
  module HtmlCustom
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html_format, type: String
      field :html, type: String

      permit_params :html_format, :html

      validates :html_format, inclusion: { in: %w(Shirasagi Liquid), allow_blank: true }
    end

    class << self
      def html_format_options
        %w(SHIRASAGI Liquid).map do |v|
          [ v, v.downcase ]
        end
      end

      def html_format_shirasagi?
        html_format == "shirasagi"
      end

      def html_format_liquid?
        html_format == "liquid"
      end
    end
  end
end
