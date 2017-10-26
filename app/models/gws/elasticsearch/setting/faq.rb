class Gws::Elasticsearch::Setting::Faq
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Faq::Topic

  def translate_category(es_type, cate_name)
    @categories ||= Gws::Faq::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_faq_category_topics_path(site: cur_site, category: cate) ]
  end
end
