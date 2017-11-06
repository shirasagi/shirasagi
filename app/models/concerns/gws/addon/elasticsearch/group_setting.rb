module Gws::Addon::Elasticsearch::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words

    permit_params :elasticsearch_hosts

    validates :elasticsearch_hosts, presence: true, if: ->{ menu_elasticsearch_visible? }
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Board::Category.allowed?(action, user, opts)
      super
    end
  end

  def elasticsearch_enabled?
    Rails.logger.warn('[DEPRECATION] `elasticsearch_enabled?` is deprecated.  Please use `menu_elasticsearch_visible?` instead.')
    menu_elasticsearch_visible?
  end

  def elasticsearch_client
    return unless menu_elasticsearch_visible?
    @elasticsearch_client ||= Elasticsearch::Client.new(hosts: elasticsearch_hosts, logger: Rails.logger)
  end
end
