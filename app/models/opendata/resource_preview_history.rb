class Opendata::ResourcePreviewHistory
  include SS::Document
  include Opendata::Resource::HistoryModel

  index({ site_id: 1, previewed: -1 })

  field :previewed, type: DateTime

  self.issued_at_field = :previewed
end

class Opendata::ResourcePreviewHistory::HistoryCsv
  include ActiveModel::Model
  include Opendata::Resource::HistoryCsvModel

  attr_accessor :cur_site, :items

  self.csv_headers = %i[
    previewed full_url dataset_id dataset_name dataset_areas dataset_categories dataset_estat_categories
    resource_id resource_name resource_filename resource_source_url remote_addr user_agent
  ].freeze

  self.model = Opendata::ResourcePreviewHistory
end

class Opendata::ResourcePreviewHistory::ArchiveFile
  include SS::Model::File
  include Opendata::Resource::HistoryArchiveFileModel
end
