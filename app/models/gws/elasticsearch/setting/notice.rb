class Gws::Elasticsearch::Setting::Notice
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Notice::Post

  def menu_label
    cur_site.menu_notice_label.presence || I18n.t('modules.gws/notice')
  end

  def search_types
    return [] unless cur_site.menu_notice_visible?
    return [] unless Gws.module_usable?(:notice, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Notice::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_notice_readables_path(site: cur_site, folder_id: '-', category_id: cate) ]
  end

  private

  def and_public(_date = nil)
    if cur_site.notice_back_number_menu_visible?
      [ { term: { 'state' => 'public' } } ]
    else
      super
    end
  end
end
