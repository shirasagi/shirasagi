class Gws::Elasticsearch::Setting::All
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  attr_accessor :cur_site, :cur_user

  def allowed?(method)
    # Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.all? do |type|
    #   next true if type == 'all'
    #   setting = "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
    #   setting.allowed?(method)
    # end
    false
  end

  def menu_label
    I18n.t('gws/elasticsearch.tabs.all')
  end

  def manageable_filter
    {}
  end

  def search_settings
    all_settings
  end

  def search_types
    search_types = []
    all_settings.each do |setting|
      search_types += setting.search_types
    end
    search_types.compact.uniq
  end

  def translate_type(es_type)
    setting = find_setting(es_type)
    if setting.present?
      setting.menu_label
    else
      es_type
    end
  end

  def translate_category(es_type, cate_name, opts = {})
    setting = find_setting(es_type)
    return if setting.blank?

    setting.translate_category(es_type, cate_name)
  end

  private

  def all_settings
    @all_settings ||= begin
      settings = Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.map do |type|
        next nil if type == 'all'
        "Gws::Elasticsearch::Setting::#{type.classify}".constantize.new(cur_site: cur_site, cur_user: cur_user)
      end
      settings.compact
    end
  end

  def find_setting(es_type)
    return unless es_type

    es_type = es_type.to_s.to_sym

    # find last setting
    found = nil
    all_settings.each do |setting|
      found = setting if setting.search_types.include?(es_type)
    end
    found
  end
end
