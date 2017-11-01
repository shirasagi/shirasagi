class Gws::Elasticsearch::Setting::Workflow
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  self.model = Gws::Workflow::File

  def search_types
    search_types = []
    search_types << Gws::Workflow::File.collection_name if allowed?(:read)
    search_types
  end
end
