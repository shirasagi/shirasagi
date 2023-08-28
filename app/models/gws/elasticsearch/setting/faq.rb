class Gws::Elasticsearch::Setting::Faq
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Faq::Topic

  def menu_label
    cur_site.menu_faq_label.presence || I18n.t('modules.gws/faq')
  end

  def search_types
    return [] unless cur_site.menu_faq_visible?
    return [] unless Gws.module_usable?(:faq, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Faq::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_faq_topics_path(site: cur_site, mode: '-', category: cate) ]
  end
end
