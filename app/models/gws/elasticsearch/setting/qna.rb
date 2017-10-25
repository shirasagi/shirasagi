class Gws::Elasticsearch::Setting::Qna
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Qna::Post.collection_name if Gws::Qna::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
