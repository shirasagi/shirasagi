class Cms::Elasticsearch::Searcher
  include ActiveModel::Model
  include SS::PermitParams

  DEFAULT_FIELD_NAME = 'text_index'.freeze

  attr_accessor :setting, :keyword, :category_name, :article_node_ids, :category_names
  attr_writer :index, :type, :field_name, :from, :size, :aggregate_size

  permit_params :keyword, :type, :category_name, article_node_ids: [], category_names: []

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

  def aggregate_size
    @aggregate_size ||= 10
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
    return unless client

    query = {}
    query[:bool] = {}
    query[:bool][:must] = []

    if keyword.present?
      query[:bool][:must] << { simple_query_string: { query: keyword, fields: [field_name].flatten, default_operator: 'AND' } }
    end

    if type == 'page'
      query[:bool][:must_not] ||= []
      query[:bool][:must_not] << { exists: { field: 'attachment' } }
    elsif type == 'file'
      query[:bool][:must] << { exists: { field: 'attachment' } }
    end

    if category_name.present?
      query[:bool][:must] << { term: { categories: category_name } }
    end

    if article_node_ids.present?
      article_node_query = {}
      article_node_query[:bool] = {}
      article_node_query[:bool][:filter] = []
      setting.cur_node.st_article_nodes.in(id: article_node_ids).each do |node|
        article_node_query[:bool][:filter] << { match_phrase: { filename: node.url } }
      end
      query[:bool][:must] << article_node_query
    end

    if category_names.present?
      query[:bool][:must] << { terms: { categories: category_names } }
    end

    query[:bool][:filter] = {}
    query[:bool][:filter][:bool] = {}
    query[:bool][:filter][:bool][:minimum_should_match] = 1
    query[:bool][:filter][:bool][:should] = filters

    aggs = {}
    aggs[:group_by_categories] = { terms: { field: 'categories', size: aggregate_size } }

    search_params = { index: index, from: from, size: size, body: { query: query, aggs: aggs } }
    #search_params[:type] = type if type.present?

    client.search(search_params)
  end
end
