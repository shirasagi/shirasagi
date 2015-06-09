module Rss::Addon
  module Page
    module Body
      extend SS::Addon
      extend ActiveSupport::Concern

      set_order 300

      included do
        field :rss_link, type: String
        field :html, type: String
        permit_params :rss_link, :html
      end
    end
  end

  module Import
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    RSS_REFRESH_METHOD_MANUAL = 'manual'.freeze
    RSS_REFRESH_METHOD_AUTO = 'auto'.freeze
    RSS_REFRESH_METHODS = [ RSS_REFRESH_METHOD_MANUAL, RSS_REFRESH_METHOD_AUTO ].freeze

    included do
      field :rss_url, type: String
      field :rss_max_docs, type: Integer
      field :rss_refresh_method, type: String
      permit_params :rss_url, :rss_max_docs, :rss_refresh_method
    end

    public
      def rss_refresh_method_options
        RSS_REFRESH_METHODS.map { |m| [ I18n.t("rss.options.rss_refresh_method.#{m}"), m ] }.to_a
      end
  end
end
