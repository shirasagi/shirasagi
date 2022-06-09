module Cms::Elasticsearch
  module_function

  SETTINGS_PATH = Rails.root.join('vendor', 'elasticsearch', 'settings.json').freeze
  MAPPINGS_PATH = Rails.root.join('vendor', 'elasticsearch', 'mappings.json').freeze
  DEFAULT_SYNONYM_PATH = "/etc/elasticsearch/synonym.txt".freeze
  INGEST_ATTACHMENT_PATH = Rails.root.join('vendor', 'elasticsearch', 'ingest_attachment.json').freeze

  def index_name_of(site:)
    "s#{site.id}"
  end

  def create_index(site:, index: nil, synonym: false)
    settings = JSON.parse(::File.read(SETTINGS_PATH))

    if synonym
      settings["analysis"]["analyzer"]["my_ja_analyzer"]["filter"].push("synonym")
      settings["analysis"]["filter"]["synonym"] = {
        type: "synonym",
        synonyms_path: synonym.is_a?(String) ? synonym : DEFAULT_SYNONYM_PATH
      }
    end

    mappings = JSON.parse(::File.read(MAPPINGS_PATH))

    body = { settings: settings, mappings: mappings }
    index ||= ::Cms::Elasticsearch.index_name_of(site: site)
    site.elasticsearch_client.indices.create(index: index, body: body)
  end

  def drop_index(site:, index: nil)
    index ||= ::Cms::Elasticsearch.index_name_of(site: site)
    site.elasticsearch_client.indices.delete(index: index)
  end

  def refresh_index(site:, index: nil)
    index ||= ::Cms::Elasticsearch.index_name_of(site: site)
    site.elasticsearch_client.indices.refresh(index: index)
  end

  def init_ingest(site:)
    settings = JSON.parse(::File.read(INGEST_ATTACHMENT_PATH))
    site.elasticsearch_client.ingest.put_pipeline(id: 'attachment', body: settings)
  end
end
