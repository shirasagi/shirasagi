class Gws::Elasticsearch::Setting::Survey
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Survey::Form

  def menu_label
    cur_site.menu_survey_label.presence || I18n.t('modules.gws/survey')
  end

  def search_types
    return [] unless cur_site.menu_survey_visible?
    return [] unless Gws.module_usable?(:survey, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Survey::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_survey_editables_path(site: cur_site, folder_id: '-', category_id: cate) ]
  end

  def readable_filter
    {}
  end
end
