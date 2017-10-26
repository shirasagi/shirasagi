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
end
