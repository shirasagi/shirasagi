module Opendata::Addon::UrlRdfStore
  extend ActiveSupport::Concern
  include Opendata::Addon::RdfStore::Model

  def graph_name
    dataset.full_url.sub(/\.html$/, "") + "/url_resource/#{id}/"
  end
end
