class Gws::Elasticsearch::Setting::Share
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Share::File

  def menu_label
    @cur_site.menu_share_label || I18n.t('modules.gws/share')
  end

  def search_types
    search_types = []
    search_types << :gws_share_files if allowed?(:read)
    search_types
  end

  def translate_category(es_type, cate_name)
    @categories ||= Gws::Share::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_share_files_path(site: cur_site, category: cate) ]
  end
end
