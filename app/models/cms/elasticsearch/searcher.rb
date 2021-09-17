class Cms::Elasticsearch::Searcher
  include ActiveModel::Model
  include SS::PermitParams

  DEFAULT_FIELD_NAME = 'text_index'.freeze

  attr_accessor :setting, :keyword, :category_id
  attr_writer :index, :type, :field_name, :from, :size

  permit_params :keyword, :category_id

  def index
    @index ||= "s#{setting.cur_site.id}"
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
    query[:bool][:must] = [{ simple_query_string: { query: keyword, fields: [field_name].flatten, default_operator: 'AND' } }]

    if category_id.present?
      query[:bool][:must] << { term: { category_ids: category_id } }
    end

    query[:bool][:filter] = {}
    query[:bool][:filter][:bool] = {}
    query[:bool][:filter][:bool][:minimum_should_match] = 1
    query[:bool][:filter][:bool][:should] = filters

    search_params = { index: index, from: from, size: size, body: { query: query } }
    #search_params[:type] = type if type.present?

    client.search(search_params)
  end
end
