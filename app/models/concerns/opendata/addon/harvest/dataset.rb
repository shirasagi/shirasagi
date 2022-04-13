module Opendata::Addon::Harvest::Dataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :uuid, type: String, default: nil

    belongs_to :harvest_importer, class_name: 'Opendata::Harvest::Importer'
    #belongs_to :harvest_importer_report, class_name: 'Opendata::Harvest::Importer::Report'

    field :harvest_imported, type: DateTime, default: nil
    field :harvest_imported_url, type: String, default: nil
    field :harvest_imported_attributes, type: Hash, default: {}

    field :harvest_source_url, type: String, default: nil
    field :harvest_host, type: String, default: nil
    field :harvest_api_type, type: String, default: nil
    field :harvest_text_index, type: String, default: ""

    before_validation :set_uuid
    before_validation :set_harvest_text_index, if: -> { harvest_imported.present? }

    validates :uuid, presence: true
  end

  def reset_harvest_attributes
    self.harvest_importer = nil
    self.harvest_importer_id = nil

    self.harvest_imported = nil
    self.harvest_imported_url = nil
    self.harvest_imported_attributes = {}

    self.harvest_source_url = nil
    self.harvest_host = nil
    self.harvest_api_type = nil
    self.harvest_text_index = ""
  end

  def harvest_ckan_groups
    ckan_groups = harvest_imported_attributes["groups"].to_a
    ckan_groups.map { |g| g["display_name"] }
  end

  def harvest_ckan_tags
    ckan_tags = harvest_imported_attributes["tags"].to_a
    ckan_tags.map { |g| g["display_name"] }
  end

  def harvest_shirasagi_categories
    shirasagi_categories = harvest_imported_attributes["categories"].to_a
    if harvest_api_type != "shirasagi_scraper"
      shirasagi_categories = shirasagi_categories.map { |c| c["name"] }
    end
    shirasagi_categories
  end

  def harvest_shirasagi_estat_categories
    shirasagi_estat_categories = harvest_imported_attributes["estat_categories"].to_a
    if harvest_api_type != "shirasagi_scraper"
      shirasagi_estat_categories = shirasagi_estat_categories.map { |c| c["name"] }
    end
    shirasagi_estat_categories
  end

  def harvest_shirasagi_areas
    shirasagi_areas = harvest_imported_attributes["areas"].to_a
    if harvest_api_type != "shirasagi_scraper"
      shirasagi_areas = shirasagi_areas.map { |c| c["name"] }
    end
    shirasagi_areas
  end

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def set_harvest_text_index
    texts = []
    %w(name text).map do |name|
      text = send(name)
      next if text.blank?
      text.gsub!(/\s+/, " ")
      texts << text
    end

    if /^ckan/.match?(harvest_api_type)
      texts += harvest_ckan_groups
      texts += harvest_ckan_tags
    end

    # resources
    texts += resources.pluck(:harvest_text_index)

    self.harvest_text_index = texts.uniq.join(" ")
  end
end
