class Gws::Elasticsearch::Setting::All
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.each do |type|
      next if type == 'all'
      setting = "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
      search_types += setting.search_types
    end
    search_types.compact.uniq
  end
end
