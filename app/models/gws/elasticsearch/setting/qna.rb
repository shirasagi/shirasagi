class Gws::Elasticsearch::Setting::Qna
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Qna::Topic

  def menu_label
    cur_site.menu_qna_label.presence || I18n.t('modules.gws/qna')
  end

  def search_types
    return [] unless cur_site.menu_qna_visible?
    return [] unless Gws.module_usable?(:qna, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Qna::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_qna_topics_path(site: cur_site, mode: '-', category: cate) ]
  end
end
