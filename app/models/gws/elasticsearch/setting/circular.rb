class Gws::Elasticsearch::Setting::Circular
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Circular::Post

  def menu_label
    cur_site.menu_circular_label.presence || I18n.t('modules.gws/circular')
  end

  def search_types
    search_types = []
    return search_types unless cur_site.menu_circular_visible?
    return search_types unless Gws.module_usable?(:circular, cur_site, cur_user)

    if Gws::Circular::Post.allowed?(:read, @cur_user, site: @cur_site)
      search_types << Gws::Circular::Post.collection_name
    end
    search_types
  end

  def translate_category(es_type, cate_name, opts = {})
    # @categories ||= Gws::Board::Category.site(cur_site).to_a
    # cate = @categories.find { |cate| cate.name == cate_name }
    # return if cate.blank?
    #
    # [ cate, url_helpers.gws_circular_category_topics_path(site: cur_site, category: cate) ]
  end

  def readable_filter
    query1 = {}
    query1[:bool] = {}
    query1[:bool][:must] = []
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'member_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'member_group_ids' } } } }
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'member_custom_group_ids' } } } }

    query2 = {}
    query2[:bool] = {}
    query2[:bool][:must] = { term: { member_ids: cur_user.id } }

    query3 = {}
    query3[:bool] = {}
    query3[:bool][:must] = []
    query3[:bool][:must] << { terms: { member_group_ids: cur_user.group_ids } }

    custom_group_ids = Gws::CustomGroup.member(cur_user).map(&:id)
    if custom_group_ids.present?
      query4 = {}
      query4[:bool] = {}
      query4[:bool][:must] = []
      query4[:bool][:must] << { terms: { member_custom_group_ids: custom_group_ids } }
    end

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = [ query1, query2, query3 ]
    query0[:bool][:should] << query4 if query4.present?
    query0[:bool][:minimum_should_match] = 1

    query0

    filter_query = {}
    filter_query[:bool] = {}
    filter_query[:bool][:must] = []
    filter_query[:bool][:must] += and_public
    filter_query[:bool][:must] << query0
    filter_query
  end
end
