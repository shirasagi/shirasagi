class Gws::Elasticsearch::Setting::Faq
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Faq::Post.collection_name if Gws::Faq::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
