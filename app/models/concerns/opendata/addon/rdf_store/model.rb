module Opendata::Addon::RdfStore::Model
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :rdf_iri, type: String
    field :rdf_error, type: String

    validate :validate_fuseki
    after_save :save_rdf_graph, if: ->{ in_file.present? || format_change.present? }
    before_destroy :remove_rdf_graph
  end

  def state_changed
    save_rdf_graph rescue nil
  end

  def validate_and_destroy
    return false unless self.valid?
    self.destroy
  end

  private

  def validate_fuseki
    Opendata::Sparql.select('select distinct * where { graph ?g { ?s ?p ?o . } } limit 0', 'HTML')
  rescue
    message = I18n.t('opendata.errors.messages.cannot_connect_fuseki')
    message << I18n.t('errors.messages.contact_system_administrator')
    self.errors.add :base, message
  end

  def save_rdf_graph
    if format.casecmp("TTL") == 0
      remove_rdf_graph
      send_rdf_graph if dataset.state == "public"
    elsif rdf_iri.present?
      remove_rdf_graph
      set rdf_iri: nil, rdf_error: nil
    end
  rescue => e
    set rdf_iri: nil, rdf_error: I18n.t("opendata.errors.messages.invalid_rdf")
    Rails.logger.error("#{I18n.t("opendata.errors.messages.invalid_rdf")}\n" \
      "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def send_rdf_graph
    if Opendata::Sparql.save graph_name, path
      set rdf_iri: graph_name, rdf_error: nil
      Rails.logger.info(I18n.t("opendata.messages.sent_rdf_success"))
    end
  end

  def remove_rdf_graph
    name = rdf_iri || graph_name
    Opendata::Sparql.clear name if name
  end
end
