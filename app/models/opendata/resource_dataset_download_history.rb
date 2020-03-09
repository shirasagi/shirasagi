# ダウンロード履歴は Opendata::ResourceDownloadHistory へ統合した。
# 集計のためにしばらく（1年ぐらい）は必要で、互換性のために残している。
class Opendata::ResourceDatasetDownloadHistory
  include SS::Document
  include SS::Reference::Site

  field :dataset_id, type: Integer
  field :dataset_name, type: String

  field :dataset_areas, type: Array, default: []
  field :dataset_categories, type: Array, default: []
  field :dataset_estat_categories, type: Array, default: []

  field :resource_id, type: Integer
  field :resource_name, type: String
  field :resource_filename, type: String
  field :resource_source_url, type: String
  field :resource_format, type: String

  field :full_url, type: String
  field :downloaded, type: DateTime
  field :remote_addr, type: String
  field :user_agent, type: String
end
