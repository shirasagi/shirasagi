module Gws::Elasticsearch::Setting::Base
  extend ActiveSupport::Concern

  included do
    cattr_accessor :model
    attr_accessor :cur_site, :cur_user
  end

  def allowed?(method)
    model.allowed?(method, cur_user, site: cur_site)
  end

  def search_types
    search_types = []
    search_types << model.collection_name if allowed?(:read)
    search_types
  end
end
