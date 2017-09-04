class Gws::Elasticsearch::Searcher
  include ActiveModel::Model

  attr_accessor :hosts, :index, :type, :field_name, :keyword

  class << self
    def search(site, type, keyword)
      searcher = Gws::Elasticsearch::Searcher.new(
        hosts: site.elasticsearch_hosts, index: "g#{site.id}", type: type,
        field_name: 'text_index', keyword: keyword
      )

      searcher.search
    end
  end

  def search
    client.search(index: index, type: type, q: "#{field_name}:#{keyword}")
  end

  def client
    @client ||= Elasticsearch::Client.new(hosts: hosts, logger: Rails.logger)
  end
end
