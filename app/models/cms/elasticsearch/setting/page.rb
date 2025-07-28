class Cms::Elasticsearch::Setting::Page
  include ActiveModel::Model
  include Gws::Elasticsearch::Setting::Base

  attr_accessor :cur_node

  self.model = Cms::Page

  def search_settings
    []
  end

  def search_types
    [model.collection_name]
  end
end
