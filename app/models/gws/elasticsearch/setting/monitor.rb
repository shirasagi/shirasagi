class Gws::Elasticsearch::Setting::Monitor
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Monitor::Topic

  def menu_label
    cur_site.menu_monitor_label.presence || I18n.t('modules.gws/monitor')
  end

  def search_types
    return [] unless cur_site.menu_monitor_visible?
    return [] unless Gws.module_usable?(:monitor, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Monitor::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_monitor_topics_path(site: cur_site, category: cate) ]
  end

  def cur_group
    cur_group = cur_user.gws_default_group(cur_site)
  end

  def readable_filter
    query1 = {}
    query1[:bool] = {}
    query1[:bool][:must] = []
    query1[:bool][:must] << { bool: { must_not: { exists: { 'field' => 'readable_group_ids' } } } }

    # attend_group_ids stored as readable_group_ids
    query2 = {}
    query2[:bool] = {}
    query2[:bool][:must] = { term: { readable_group_ids: (cur_group ? cur_group.id : -1) } }

    query0 = {}
    query0[:bool] = {}
    query0[:bool][:should] = [ query1, query2 ]
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
