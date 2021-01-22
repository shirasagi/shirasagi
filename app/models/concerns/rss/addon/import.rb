module Rss::Addon
  module Import
    extend ActiveSupport::Concern
    extend SS::Addon

    RSS_REFRESH_METHOD_MANUAL = 'manual'.freeze
    RSS_REFRESH_METHOD_AUTO = 'auto'.freeze
    RSS_REFRESH_METHODS = [ RSS_REFRESH_METHOD_AUTO, RSS_REFRESH_METHOD_MANUAL ].freeze

    included do
      cattr_accessor :weather_xml, instance_accessor: false
      cattr_accessor :default_rss_max_docs, instance_accessor: false
      field :rss_url, type: String
      field :rss_max_docs, type: Integer, default: ->{ self.class.default_rss_max_docs }
      field :rss_refresh_method, type: String
      field :page_state, type: String
      permit_params :rss_url, :rss_max_docs, :rss_refresh_method, :page_state
      validates :page_state, inclusion: { in: %w(public closed), allow_blank: true }
    end

    def rss_refresh_method_options
      RSS_REFRESH_METHODS.map { |m| [ I18n.t("rss.options.rss_refresh_method.#{m}"), m ] }.to_a
    end

    def page_state_options
      %w(public closed).map { |value| [I18n.t("ss.options.state.#{value}"), value] }
    end
  end
end
