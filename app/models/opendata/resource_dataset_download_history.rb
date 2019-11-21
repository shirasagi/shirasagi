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

  field :full_url, type: String
  field :downloaded, type: DateTime
  field :remote_addr, type: String
  field :user_agent, type: String

  class << self
    def create_history(site:, dataset:, resource:, remote_addr:, user_agent:, downloaded:)
      self.create(
        cur_site: site,
        dataset_id: dataset.id,
        dataset_name: dataset.name,
        dataset_areas: dataset.areas.order_by(order: 1).pluck(:name),
        dataset_categories: dataset.categories.order_by(order: 1).pluck(:name),
        dataset_estat_categories: dataset.estat_categories.order_by(order: 1).pluck(:name),
        resource_id: resource.id,
        resource_name: resource.name,
        resource_filename: resource.filename,
        resource_source_url: resource.source_url,
        full_url: dataset.full_url,
        downloaded: (downloaded || Time.zone.now),
        remote_addr: remote_addr,
        user_agent: user_agent
      )
    end
  end
end
