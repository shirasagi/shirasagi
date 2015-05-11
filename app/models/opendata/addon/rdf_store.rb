module Opendata::Addon::RdfStore
  extend ActiveSupport::Concern
  include Opendata::Addon::RdfStore::Model

  def graph_name
    dataset.full_url.sub(/\.html$/, "") + "/resource/#{id}/"
  end
end
