module SS::Addon::Elasticsearch::SiteSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :elasticsearch_hosts, type: SS::Extensions::Words
    field :elasticsearch_deny, type: SS::Extensions::Lines, default: '404.html'
    field :elasticsearch_indexes, type: SS::Extensions::Words
    embeds_ids :elasticsearch_sites, class_name: "Cms::Site"

    permit_params :elasticsearch_hosts, :elasticsearch_deny, :elasticsearch_indexes, elasticsearch_site_ids: []

    after_save :deny_elasticsearch_paths, if: ->{ @db_changes["elasticsearch_deny"] }
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

  private

  def deny_elasticsearch_paths
    es_client = elasticsearch_client
    return unless es_client

    index_name = "s#{id}"
    index_type = Cms::Page.collection_name

    elasticsearch_deny.each do |path|
      path.slice!(0) if path.start_with?('/')
      begin
        es_client.delete(index: index_name, type: index_type, id: path)
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
      end
    end
  end
end
