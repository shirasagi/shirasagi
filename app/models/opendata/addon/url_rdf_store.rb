module Opendata::Addon::UrlRdfStore
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 202

  included do
    field :rdf_iri, type: String
    field :rdf_error, type: String

    after_save :save_rdf_store, if: ->{ in_file.present? || format_change.present? }
    before_destroy :remove_rdf_store
  end

  def graph_name
    dataset.full_url.sub(/\.html$/, "") + "/url_resource/#{id}/"
  end

  def save_rdf_store
    if format.upcase == "TTL"
      remove_rdf_store
      begin
        if Opendata::Sparql.save graph_name, path
          set rdf_iri: graph_name, rdf_error: nil
        end
      rescue => e
        set rdf_iri: nil, rdf_error: I18n.t("opendata.errors.messages.invalid_rdf")
      end
    elsif rdf_iri.present?
      remove_rdf_store
      set rdf_iri: nil, rdf_error: nil
    end
  end

  def remove_rdf_store
    name = rdf_iri || graph_name
    Opendata::Sparql.clear name if name
  end
end
