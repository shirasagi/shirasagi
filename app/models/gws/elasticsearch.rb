module Gws::Elasticsearch
  extend Gws::ModulePermission

  module_function

  def index_name_of(site:)
    "g#{site.id}"
  end

  def create_index(site:, synonym: false)
    ::Cms::Elasticsearch.create_index(site: site, index: Gws::Elasticsearch.index_name_of(site: site), synonym: synonym)
  end

  def drop_index(site:)
    ::Cms::Elasticsearch.drop_index(site: site, index: Gws::Elasticsearch.index_name_of(site: site))
  end

  def refresh_index(site:)
    ::Cms::Elasticsearch.refresh_index(site: site, index: Gws::Elasticsearch.index_name_of(site: site))
  end

  def init_ingest(site:)
    ::Cms::Elasticsearch.init_ingest(site: site)
  end

  def mappings_keys
    @mappings_keys ||= begin
      json = JSON.parse(::File.read("#{Rails.root}/vendor/elasticsearch/mappings.json"))
      json["properties"].keys.freeze
    end
  end
end
