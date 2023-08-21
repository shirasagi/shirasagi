module Opendata::DatasetBulkDownload
  extend ActiveSupport::Concern

  def exceeded_bulk_download_filesize?(datasets)
    datasets = datasets.select(&:zip_exist?)
    size = datasets.sum(&:zip_size)
    size > SS.config.opendata.bulk_download_max_filesize
  end

  def bulk_download_url(datasets)
    "#{url}bulk_download?#{{ ids: datasets.map(&:id) }.to_query}"
  end
end
