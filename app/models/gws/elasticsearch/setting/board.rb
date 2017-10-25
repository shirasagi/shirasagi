class Gws::Elasticsearch::Setting::Board
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Board::Post.collection_name if Gws::Board::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
