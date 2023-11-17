module Opendata::Addon::Metadata::Resource
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :uuid, type: String, default: nil
    field :revision_id, type: String, default: nil

    belongs_to :metadata_importer, class_name: 'Opendata::Metadata::Importer'
    #belongs_to :metadata_importer_report, class_name: 'Opendata::Metadata::Importer::Report'

    field :metadata_imported, type: DateTime, default: nil
    field :metadata_imported_url, type: String, default: nil
    field :metadata_imported_attributes, type: Hash, default: {}

    field :metadata_host, type: String, default: nil
    field :metadata_text_index, type: String, default: ""

    field :metadata_file_access_url, type: String
    field :metadata_file_download_url, type: String
    field :metadata_file_released, type: DateTime
    field :metadata_file_updated, type: DateTime
    field :metadata_file_terms_of_service, type: String
    field :metadata_file_related_document, type: String
    field :metadata_file_follow_standards, type: String

    before_validation :set_uuid
    before_validation :set_metadata_text_index, if: -> { metadata_imported.present? }

    validates :uuid, presence: true

    before_save :set_revision_id
  end

  def data_url
    if source_url.present?
      # a resource referencing other site's resource
      source_url
    elsif respond_to?(:original_url) && original_url.present?
      # a url resource
      original_url
    elsif file
      file.full_url
    else
      ""
    end
  end

  def reset_metadata_attributes
    self.metadata_importer = nil
    self.metadata_importer_id = nil

    self.metadata_imported = nil
    self.metadata_imported_url = nil
    self.metadata_imported_attributes = {}

    self.metadata_host = nil
    self.metadata_text_index = ""

    self.metadata_file_access_url = nil
    self.metadata_file_download_url = nil
    self.metadata_file_released = nil
    self.metadata_file_updated = nil
    self.metadata_file_terms_of_service = nil
    self.metadata_file_related_document = nil
    self.metadata_file_follow_standards = nil
  end

  def set_metadata_text_index
    texts = []
    %w(name text filename).map do |name|
      text = send(name)
      next if text.blank?
      text.gsub!(/\s+/, " ")
      texts << text
    end

    # license
    texts << license.name if license

    self.metadata_text_index = texts.uniq.join(" ")
  end

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def set_revision_id
    return true if !changed?
    return true if !record_timestamps
    self.revision_id = SecureRandom.uuid
  end
end
