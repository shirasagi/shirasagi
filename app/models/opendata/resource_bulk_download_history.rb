class Opendata::ResourceBulkDownloadHistory
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
    def create_history(site:, dataset:, resource:, request:, downloaded:)
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
        remote_addr: (request.env["HTTP_X_REAL_IP"] || request.remote_ip),
        user_agent: request.user_agent
      )
    end

    def update_histories
      ids = self.all.pluck(:id)
      ids.each_with_index do |id, idx|
        Rails.logger.info "update #{self} : #{idx + 1} / #{ids.count}"
        puts "update #{self} : #{idx + 1} / #{ids.count}"

        item = self.find(id) rescue nil
        next unless item

        dataset = Opendata::Dataset.find(item.dataset_id) rescue nil
        next unless dataset

        item.set(dataset_name: dataset.name)
        item.set(dataset_areas: dataset.areas.order_by(order: 1).pluck(:name))
        item.set(dataset_categories: dataset.categories.order_by(order: 1).pluck(:name))
        item.set(dataset_estat_categories: dataset.estat_categories.order_by(order: 1).pluck(:name))
        item.set(full_url: dataset.full_url)

        resource = dataset.resources.where(id: item.resource_id).first
        next unless resource

        item.set(resource_name: resource.name)
        item.set(resource_filename: resource.filename)
        item.set(resource_source_url: resource.source_url)
      end
    end
  end
end
