module Gws::Addon::Elasticsearch::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :elasticsearch_state, type: String, default: 'disabled'
    field :elasticsearch_hosts, type: SS::Extensions::Words

    permit_params :elasticsearch_state, :elasticsearch_hosts

    validates :elasticsearch_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }
    validates :elasticsearch_hosts, presence: true, if: ->{ elasticsearch_enabled? }
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Board::Category.allowed?(action, user, opts)
      super
    end
  end

  def elasticsearch_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def elasticsearch_enabled?
    elasticsearch_state == 'enabled'
  end

  def elasticsearch_client
    return unless elasticsearch_enabled?
    @elasticsearch_client ||= Elasticsearch::Client.new(hosts: elasticsearch_hosts, logger: Rails.logger)
  end
end
