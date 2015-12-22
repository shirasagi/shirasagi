module Rss::Addon
  module Import
    extend ActiveSupport::Concern
    extend SS::Addon

    RSS_REFRESH_METHOD_MANUAL = 'manual'.freeze
    RSS_REFRESH_METHOD_AUTO = 'auto'.freeze
    RSS_REFRESH_METHODS = [ RSS_REFRESH_METHOD_AUTO, RSS_REFRESH_METHOD_MANUAL ].freeze

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
