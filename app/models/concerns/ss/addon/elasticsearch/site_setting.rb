module SS::Addon::Elasticsearch::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words

    permit_params :elasticsearch_hosts

    validates :elasticsearch_hosts, presence: true
  end

  def menu_elasticsearch_visible?
    elasticsearch_enabled?
  end

  def elasticsearch_enabled?
    elasticsearch_hosts.present?
  end

  def elasticsearch_client
    return unless elasticsearch_enabled?
    @elasticsearch_client ||= Elasticsearch::Client.new(hosts: elasticsearch_hosts, logger: Rails.logger)
  end
end
