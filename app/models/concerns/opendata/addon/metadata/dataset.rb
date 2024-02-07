module Opendata::Addon::Metadata::Dataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :uuid, type: String, default: nil

    belongs_to :metadata_importer, class_name: 'Opendata::Metadata::Importer'
    #belongs_to :metadata_importer_report, class_name: 'Opendata::Metadata::Importer::Report'

    field :metadata_imported, type: DateTime, default: nil
    field :metadata_imported_url, type: String, default: nil
    field :metadata_imported_attributes, type: Hash, default: {}

    field :metadata_source_url, type: String, default: nil
    field :metadata_host, type: String, default: nil
    field :metadata_text_index, type: String, default: ""
    field :metadata_dataset_id, type: String
    field :metadata_japanese_local_goverment_code, type: String
    field :metadata_local_goverment_name, type: String
    field :metadata_dataset_keyword, type: SS::Extensions::Words
    field :metadata_dataset_released, type: DateTime
    field :metadata_dataset_updated, type: DateTime
    field :metadata_dataset_url, type: String
    field :metadata_dataset_update_frequency, type: String
    field :metadata_dataset_follow_standards, type: String
    field :metadata_dataset_related_document, type: String
    field :metadata_dataset_target_period, type: String
    field :metadata_dataset_contact_name, type: String
    field :metadata_dataset_contact_email, type: String
    field :metadata_dataset_contact_tel, type: String
    field :metadata_dataset_contact_ext, type: String
    field :metadata_dataset_contact_form_url, type: String
    field :metadata_dataset_contact_remark, type: String
    field :metadata_dataset_remark, type: String

    permit_params :metadata_dataset_id, :metadata_japanese_local_goverment_code, :metadata_local_goverment_name,
      :metadata_dataset_keyword, :metadata_dataset_released, :metadata_dataset_updated, :metadata_dataset_url,
      :metadata_dataset_update_frequency, :metadata_dataset_follow_standards, :metadata_dataset_related_document,
      :metadata_dataset_target_period, :metadata_dataset_contact_name, :metadata_dataset_contact_email,
      :metadata_dataset_contact_tel, :metadata_dataset_contact_ext, :metadata_dataset_contact_form_url,
      :metadata_dataset_contact_remark, :metadata_dataset_remark

    before_validation :set_uuid
    before_validation :set_metadata_text_index, if: -> { metadata_imported.present? }

    validates :uuid, presence: true
    validate :validate_metadata_dataset
  end

  def reset_metadata_attributes
    self.metadata_importer = nil
    self.metadata_importer_id = nil

    self.metadata_imported = nil
    self.metadata_imported_url = nil
    self.metadata_imported_attributes = {}

    self.metadata_source_url = nil
    self.metadata_host = nil
    self.metadata_text_index = ""
    self.metadata_dataset_id = nil
    self.metadata_japanese_local_goverment_code = nil
    self.metadata_local_goverment_name = nil
    self.metadata_dataset_keyword = nil
    self.metadata_dataset_released = nil
    self.metadata_dataset_updated = nil
    self.metadata_dataset_url = nil
    self.metadata_dataset_update_frequency = nil
    self.metadata_dataset_follow_standards = nil
    self.metadata_dataset_related_document = nil
    self.metadata_dataset_target_period = nil
    self.metadata_dataset_contact_name = nil
    self.metadata_dataset_contact_email = nil
    self.metadata_dataset_contact_tel = nil
    self.metadata_dataset_contact_ext = nil
    self.metadata_dataset_contact_form_url = nil
    self.metadata_dataset_contact_remark = nil
    self.metadata_dataset_remark = nil
  end

  def metadata_dataset_category
    (metadata_imported_attributes["データセット_愛媛県分類"].presence || metadata_imported_attributes["分類"]).
      to_s.
      split(/\R|\s|\u00A0|　/)
  end

  def metadata_dataset_estat_category
    (metadata_imported_attributes["データセット_分類"].presence || metadata_imported_attributes["分類"]).
      to_s.
      split(/\R|\s|\u00A0|　/)
  end

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def set_metadata_text_index
    texts = []
    %w(name text).map do |name|
      text = send(name)
      next if text.blank?
      text.gsub!(/\s+/, " ")
      texts << text
    end

    # resources
    texts += resources.pluck(:metadata_text_index)

    self.metadata_text_index = texts.uniq.join(" ")
  end

  private

  def validate_metadata_dataset
    return if metadata_importer_id.blank?
    return if metadata_dataset_id.blank?
    return if self.class.
      where(metadata_importer_id: metadata_importer_id, name: name).
      ne(metadata_dataset_id: metadata_dataset_id).
      exists(metadata_dataset_id: true).
      blank?

    errors.add :name, :duplicate
  end
end
