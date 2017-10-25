class Gws::Elasticsearch::Searcher
  include ActiveModel::Model
  include SS::PermitParams

  DEFAULT_FIELD_NAME = 'text_index'.freeze
  WELL_KNOWN_TYPES = %w(all board faq qna monitor share).freeze

  attr_accessor :cur_site, :cur_user
  attr_accessor :index, :type, :field_name
  attr_accessor :keyword, :from, :size

  permit_params :keyword

  def index
    @index ||= "g#{cur_site.id}"
  end

  def field_name
    @field_name ||= DEFAULT_FIELD_NAME
  end

  def from
    @from ||= 0
  end

  def size
    @size ||= 10
  end

  def client
    @client ||= cur_site.elasticsearch_client
  end

  def search
    query = {}
    query[:bool] = {}
    query[:bool][:must] = { query_string: { query: keyword, default_field: field_name, default_operator: 'AND' } }
    query[:bool][:filter] = and_public
    query[:bool][:filter] << and_readable

    search_params = { index: index, from: from, size: size, body: { query: query } }
    search_params[:type] = type if type.present?
    client.search(search_params)
  end

  private

  def and_public
    query0 = { term: { 'state' => 'public' } }

    query1 = {}
    query1[:bool] = {}
    query1[:bool][:should] = []
    query1[:bool][:should] << { range: { release_date: { 'lte' => Time.zone.now.iso8601 } } }
    query1[:bool][:should] << { bool: { must_not: { exists: { 'field' => 'release_date' } } } }
    query1[:bool][:minimum_should_match] = 1

    query2 = {}
    query2[:bool] = {}
    query2[:bool][:should] = []
    query2[:bool][:should] << { range: { close_date: { 'gt' => Time.zone.now.iso8601 } } }
    query2[:bool][:should] << { bool: { must_not: { exists: { 'field' => 'close_date' } } } }
    query2[:bool][:minimum_should_match] = 1

    [ query0, query1, query2 ]
  end

  def and_readable
    query1 = {}
    query1[:bool] = {}
    query1[:bool][:must] = []
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'readable_group_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'readable_member_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'readable_custom_group_ids' } } } }

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
