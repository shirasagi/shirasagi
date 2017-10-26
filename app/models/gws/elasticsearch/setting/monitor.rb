class Gws::Elasticsearch::Setting::Monitor
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Monitor::Topic

  def translate_category(es_type, cate_name)
    @categories ||= Gws::Monitor::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_monitor_category_topics_path(site: cur_site, category: cate) ]
  end
end
