class Gws::Elasticsearch::Setting::Board
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Board::Topic

  def translate_category(es_type, cate_name)
    @categories ||= Gws::Board::Category.site(cur_site).to_a
    cate = @categories.find { |cate| cate.name == cate_name }
    return if cate.blank?

    [ cate, url_helpers.gws_board_category_topics_path(site: cur_site, category: cate) ]
  end
end
