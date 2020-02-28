class Opendata::ResourceDownloadHistory
  include SS::Document
  include Opendata::Resource::HistoryModel

  index({ site_id: 1, downloaded: -1 })

  field :downloaded, type: DateTime
  field :downloaded_by, type: String

  self.issued_at_field = :downloaded

  def downloaded_by_options
    %w(single dataset bulk).map do |v|
      [ I18n.t("opendata.downloaded_by_options.#{v}"), v ]
    end
  end
end

class Opendata::ResourceDownloadHistory::HistoryCsv
  include ActiveModel::Model
  include Opendata::Resource::HistoryCsvModel

  self.csv_headers = %i[
    downloaded downloaded_by full_url dataset_id dataset_name dataset_areas dataset_categories dataset_estat_categories
    resource_id resource_name resource_filename resource_format resource_source_url remote_addr user_agent
  ].freeze

  self.model = Opendata::ResourceDownloadHistory

  private

  def to_csv_value(item, key)
    if key == :downloaded_by
      if item.is_a?(Opendata::ResourceDatasetDownloadHistory)
        I18n.t("opendata.downloaded_by_options.dataset")
      elsif item.is_a?(Opendata::ResourceBulkDownloadHistory)
        I18n.t("opendata.downloaded_by_options.bulk")
      else
        item.label(:downloaded_by).presence || I18n.t("opendata.downloaded_by_options.single")
      end
    else
      super
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end

class Opendata::ResourceDownloadHistory::ArchiveFile
  include SS::Model::File
  include Opendata::Resource::HistoryArchiveFileModel
end
