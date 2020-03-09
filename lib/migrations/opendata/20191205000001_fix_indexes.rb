class SS::Migration20191205000001
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    models = [
      Opendata::ResourceDownloadHistory, Opendata::ResourceDownloadReport,
      Opendata::ResourcePreviewHistory, Opendata::ResourcePreviewReport,
      Opendata::DatasetAccessReport
    ]

    models.each do |model|
      model.remove_indexes
      model.create_indexes
    end
  end
end
