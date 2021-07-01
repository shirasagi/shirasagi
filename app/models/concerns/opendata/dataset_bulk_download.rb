module Opendata::DatasetBulkDownload
  extend ActiveSupport::Concern

  def exceeded_bulk_download_filesize?(datasets)
    datasets = datasets.select(&:zip_exists?)
    size = datasets.map(&:zip_size).sum
    size > SS.config.opendata.bulk_download_max_filesize
  end

  def bulk_download_url(datasets)
    "#{url}bulk_download?#{{ ids: datasets.map(&:id) }.to_query}"
  end
end
