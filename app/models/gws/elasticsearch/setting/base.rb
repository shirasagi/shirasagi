module Gws::Elasticsearch::Setting::Base
  extend ActiveSupport::Concern

  included do
    cattr_accessor :model
    attr_accessor :cur_site, :cur_user
  end

  def type
    self.class.name.underscore.sub(/^.*\//, '')
  end

  def allowed?(method)
    model.allowed?(method, cur_user, site: cur_site)
  end

  def translate_category(es_type, cate_name)
    nil
  end

  def search_settings
    search_settings = []
    search_settings << self if allowed?(:read)
    search_settings
  end

  def search_types
    search_types = []
    search_types << model.collection_name if allowed?(:read)
    search_types
  end

  def readable_filter
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

    query5 = {}
    query5[:bool] = {}
    query5[:bool][:must] = { term: { member_ids: cur_user.id } }

    if custom_group_ids.present?
      query6 = {}
      query6[:bool] = {}
      query6[:bool][:must] = []
      query6[:bool][:must] << { terms: { member_custom_group_ids: custom_group_ids } }
    end

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = [ query1, query2, query3, query5 ]
    query0[:bool][:should] << query4 if query4.present?
    query0[:bool][:should] << query6 if query6.present?
    query0[:bool][:minimum_should_match] = 1

    query0

    filter_query = {}
    filter_query[:bool] = {}
    filter_query[:bool][:must] = []
    filter_query[:bool][:must] += and_public
    filter_query[:bool][:must] << query0
    filter_query
  end

  def manageable_filter
    queries = []

    if level = cur_user.gws_role_permissions["read_other_#{model.permission_name}_#{cur_site.id}"]
      query2 = {}
      query2[:bool] = {}
      query2[:bool][:must] = []
      query2[:bool][:must] << { term: { user_ids: cur_user.id } }
      queries << query2

      query3 = {}
      query3[:bool] = {}
      query3[:bool][:must] = []
      query3[:bool][:must] << { range: { permission_level: { gte: 0, lte: level } } }
      queries << query3
    elsif level = cur_user.gws_role_permissions["read_private_#{model.permission_name}_#{cur_site.id}"]
      query2 = {}
      query2[:bool] = {}
      query2[:bool][:must] = []
      query2[:bool][:must] << { term: { user_ids: cur_user.id } }
      queries << query2

      query3 = {}
      query3[:bool] = {}
      query3[:bool][:must] = []
      query3[:bool][:must] << { terms: { group_ids: cur_user.group_ids } }
      query3[:bool][:must] << { range: { permission_level: { gte: 0, lte: level } } }
      queries << query3
    else
      query2 = {}
      query2[:bool] = {}
      query2[:bool][:must] = []
      query2[:bool][:must] << { term: { user_ids: cur_user.id } }
      queries << query2
    end

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = queries
    query0[:bool][:minimum_should_match] = 1

    query0
  end

  def build_filter
    filter_query = {}
    filter_query[:bool] = {}
    filter_query[:bool][:minimum_should_match] = 1
    filter_query[:bool][:should] = []
    filter_query[:bool][:should] << readable_filter
    manage_filter = manageable_filter
    if manage_filter.present?
      filter_query[:bool][:should] << manage_filter
    end

    type_query = {}
    type_query[:bool] = {}
    type_query[:bool][:minimum_should_match] = 1
    type_query[:bool][:should] = search_types.map { |type| { type: { value: type } } }

    query = {}
    query[:bool] = {}
    query[:bool][:must] = []
    query[:bool][:must] << filter_query
    query[:bool][:must] << type_query

    query
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

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
end
