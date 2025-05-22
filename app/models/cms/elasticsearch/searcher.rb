class Cms::Elasticsearch::Searcher
  include ActiveModel::Model
  include SS::PermitParams

  DEFAULT_FIELD_NAME = 'text_index'.freeze

  attr_accessor :setting, :sort, :keyword, :article_node_ids, :category_name, :category_names,
    :group_name, :group_ids
  attr_writer :index, :type, :field_name, :from, :size, :aggregate_size

  permit_params :sort, :keyword, :type, :category_name, :group_name, article_node_ids: [], category_names: [], group_ids: []

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

  def search_categories
    return unless client

    aggs = { categories: { terms: { field: 'categories', size: aggregate_size }}}
    client.search({ index: index, body: { aggs: aggs } })
  end

  def search
    return unless client

    query = {}
    query[:bool] = {}
    query[:bool][:must] = []

    if keyword.present?
      if field_name.is_a?(String)
        query[:bool][:must] << { query_string: { query: keyword, default_operator: 'AND', default_field: field_name } }
      else
        query[:bool][:must] << { query_string: { query: keyword, default_operator: 'AND', fields: field_name } }
      end
    end

    if type == 'page'
      query[:bool][:must_not] ||= []
      query[:bool][:must_not] << { exists: { field: 'attachment' } }
    elsif type == 'file'
      query[:bool][:must] << { exists: { field: 'attachment' } }
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
      names = category_names.reject(&:blank?)
      query[:bool][:must] << { terms: { categories: names } } if names.present?
    end

    if group_ids.present?
      ids = group_ids.reject(&:blank?)
      query[:bool][:must] << { terms: { group_ids: ids } } if ids.present?
    end

    if category_name.present?
      names = category_name.split(/[\s\/　]+/).uniq.reject(&:empty?).slice(0, 10)
      query[:bool][:must] << { terms: { categories: names } } if names.present?
    end

    if group_name.present?
      names = group_name.split(/[\s\/　]+/).uniq.reject(&:empty?).slice(0, 10)
      query[:bool][:must] << { terms: { group_names: names } } if names.present?
    end

    query[:bool][:filter] = {}
    query[:bool][:filter][:bool] = {}
    query[:bool][:filter][:bool][:minimum_should_match] = 1
    query[:bool][:filter][:bool][:should] = filters

    aggs = {}
    # aggs[:group_by_categories] = { terms: { field: 'categories', size: aggregate_size } }

    case sort
    when 'released'
      sort = [{ released: 'desc' }, '_score']
    else
      sort = [{ _score: 'desc' }]
    end

    highlight = {
      fragment_size: 140,
      number_of_fragments: 1,
      fields: {
        text_index: {}
      }
    }

    search_params = { index: index, from: from, size: size, body: { query: query, aggs: aggs, sort: sort, highlight: highlight } }
    #search_params[:type] = type if type.present?

    client.search(search_params)
  end
end
