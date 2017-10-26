class Gws::Elasticsearch::Setting::All
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def allowed?(method)
    # Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.all? do |type|
    #   next true if type == 'all'
    #   setting = "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
    #   setting.allowed?(method)
    # end
    false
  end

  def search_types
    search_types = []
    Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.each do |type|
      next if type == 'all'
      setting = "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
      search_types += setting.search_types
    end
    search_types.compact.uniq
  end

  def translate_type(es_type)
    es_type = es_type.to_sym
    type = Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.find do |type|
      next if type == 'all'
      setting = "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
      setting.search_types.include?(es_type)
    end

    if type.present?
      I18n.t("gws/elasticsearch.tabs.#{type}")
    else
      es_type
    end
  end
end
