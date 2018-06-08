class Gws::Elasticsearch::Searcher
  include ActiveModel::Model
  include SS::PermitParams

  DEFAULT_FIELD_NAME = 'text_index'.freeze
  WELL_KNOWN_TYPES = %w(all board faq qna report workflow circular monitor share memo).freeze

  attr_accessor :setting
  attr_accessor :index, :type, :field_name
  attr_accessor :keyword, :from, :size

  permit_params :keyword

  def index
    @index ||= "g#{setting.cur_site.id}"
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

  def type
    @type ||= setting.search_types
  end

  def client
    @client ||= setting.cur_site.elasticsearch_client
  end

  def filters
    @filters ||= setting.search_settings.map { |s| s.build_filter }
  end

  def search
    query = {}
    query[:bool] = {}
    query[:bool][:must] = { query_string: { query: keyword, default_field: field_name, default_operator: 'AND' } }

    query[:bool][:filter] = {}
    query[:bool][:filter][:bool] = {}
    query[:bool][:filter][:bool][:minimum_should_match] = 1
    query[:bool][:filter][:bool][:should] = filters

    search_params = { index: index, from: from, size: size, body: { query: query } }
    #search_params[:type] = type if type.present?

    client.search(search_params)
  end
end
