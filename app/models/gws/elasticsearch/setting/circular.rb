class Gws::Elasticsearch::Setting::Circular
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Circular::Topic

  def search_types
    search_types = []
    if Gws::Circular::Topic.allowed?(:read, @cur_user, site: @cur_site)
      search_types << Gws::Circular::Topic.collection_name
      search_types << Gws::Circular::Post.collection_name
    end
    search_types
  end

  def translate_category(es_type, cate_name)
    # @categories ||= Gws::Board::Category.site(cur_site).to_a
    # cate = @categories.find { |cate| cate.name == cate_name }
    # return if cate.blank?
    #
    # [ cate, url_helpers.gws_circular_category_topics_path(site: cur_site, category: cate) ]
  end
end
