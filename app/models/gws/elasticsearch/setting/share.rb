class Gws::Elasticsearch::Setting::Share
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Share::File

  def search_types
    search_types = []
    search_types << :gws_share_files if allowed?(:read)
    search_types
  end
end
