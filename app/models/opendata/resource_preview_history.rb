class Opendata::ResourcePreviewHistory
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
  field :previewed, type: DateTime
  field :remote_addr, type: String
  field :user_agent, type: String

  class << self
    def create_history(site:, dataset:, resource:, remote_addr:, user_agent:, previewed:)
      self.create(
        cur_site: site,
        dataset_id: dataset.id,
        dataset_name: dataset.name,
        dataset_areas: dataset.areas.and_public.order_by(order: 1).pluck(:name),
        dataset_categories: dataset.categories.and_public.order_by(order: 1).pluck(:name),
        dataset_estat_categories: dataset.estat_categories.and_public.order_by(order: 1).pluck(:name),
        resource_id: resource.id,
        resource_name: resource.name,
        resource_filename: resource.filename,
        resource_source_url: resource.source_url,
        full_url: dataset.full_url,
        previewed: (previewed || Time.zone.now),
        remote_addr: remote_addr,
        user_agent: user_agent
      )
    end
  end
end
