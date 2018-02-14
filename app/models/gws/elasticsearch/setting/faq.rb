class Gws::Elasticsearch::Setting::Faq
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Faq::Topic

  def menu_label
    I18n.t('modules.gws/faq')
  end

  def search_types
    return [] unless cur_site.menu_question_visible?
    super
  end

  def translate_category(es_type, cate_name)
    @categories ||= Gws::Faq::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_faq_topics_path(site: cur_site, mode: '-', category: cate) ]
  end
end
