class Gws::Elasticsearch::Setting::Memo
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user

  def search_types
    search_types = []
    search_types << Gws::Memo::Message.collection_name if Gws::Memo::Message.allowed?(:read, @cur_user, site: @cur_site)
    search_types
  end
end
