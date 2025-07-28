class Gws::Elasticsearch::Setting::Board
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Board::Topic

  def menu_label
    cur_site.menu_board_label.presence || I18n.t('modules.gws/board')
  end

  def search_types
    return [] unless cur_site.menu_board_visible?
    return [] unless Gws.module_usable?(:board, cur_site, cur_user)

    super
  end

  def translate_category(es_type, cate_name, opts = {})
    @categories ||= Gws::Board::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_board_topics_path(site: cur_site, mode: '-', category: cate) ]
  end
end
