class Gws::Elasticsearch::Searcher
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user
  attr_accessor :hosts, :index, :type, :field_name, :keyword

  class << self
    def search(site, user, type, keyword)
      searcher = Gws::Elasticsearch::Searcher.new(
       cur_site: site, cur_user: user,
        hosts: site.elasticsearch_hosts, index: "g#{site.id}", type: type,
        field_name: 'text_index', keyword: keyword
      )

      searcher.search
    end
  end

  def client
    @client ||= Elasticsearch::Client.new(hosts: hosts, logger: Rails.logger)
  end

  def search
    query = {}
    query[:bool] = {}
    query[:bool][:must] = { match: { field_name => keyword } }
    query[:bool][:filter] = and_public
    query[:bool][:filter] << and_readable

    client.search(index: index, type: type, body: { query: query})
  end

  private

  def and_public
    query0 = { term: { 'state' => 'public' } }

    query1 = {}
    query1[:bool] = {}
    query1[:bool][:should] = []
    query1[:bool][:should] << { range: { release_date: { 'lte' => Time.zone.now.iso8601 } } }
    query1[:bool][:should] << { bool: { must_not: { exists: { 'field': 'release_date' } } } }
    query1[:bool][:minimum_should_match] = 1

    query2 = {}
    query2[:bool] = {}
    query2[:bool][:should] = []
    query2[:bool][:should] << { range: { close_date: { 'gt' => Time.zone.now.iso8601 } } }
    query2[:bool][:should] << { bool: { must_not: { exists: { 'field': 'close_date' } } } }
    query2[:bool][:minimum_should_match] = 1

    [ query0, query1, query2 ]
  end

  def and_readable
    query1 = {}
    query1[:bool] = {}
    query1[:bool][:must] = []
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field': 'readable_group_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field': 'readable_member_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field': 'readable_custom_group_ids' } } } }

    query2 = {}
    query2[:bool] = {}
    query2[:bool][:must] = []
    query2[:bool][:must] << { terms: { readable_group_ids: cur_user.group_ids } }

    query3 = {}
    query3[:bool] = {}
    query3[:bool][:must] = { term: { readable_member_ids: cur_user.id } }

    custom_group_ids = Gws::CustomGroup.member(cur_user).map(&:id)
    if custom_group_ids.present?
      query4 = {}
      query4[:bool] = {}
      query4[:bool][:must] = []
      query4[:bool][:must] << { terms: { readable_custom_group_ids: custom_group_ids } }
    end

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = [ query1, query2, query3 ]
    # query0[:bool][:should] = [ query3 ]
    query0[:bool][:minimum_should_match] = 1

    query0
  end
end
