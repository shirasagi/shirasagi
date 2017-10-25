class Gws::Elasticsearch::Setting::Monitor
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Monitor::Post.collection_name if Gws::Monitor::Topic.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
