module Opendata::HistoryUpdateBase
  extend ActiveSupport::Concern

  def perform(*args)
    @options = args.extract_options!
    ids = items.pluck(:id)
    ids.each_with_index do |id, idx|
      put_log("update #{model} : #{idx + 1} / #{ids.count}")

      item = model.find(id) rescue nil
      next unless item

      dataset = Opendata::Dataset.find(item.dataset_id) rescue nil
      resource = dataset.resources.where(id: item.resource_id).first if dataset.present?
      site = item.site.presence || dataset.try(:site).presence || resource.try(:site)
      item.set(site_id: site.try(:id)) if site.present?

      next unless dataset
      item.set({
        dataset_name: dataset.name,
        dataset_areas: dataset.areas.order_by(order: 1).pluck(:name),
        dataset_categories: dataset.categories.order_by(order: 1).pluck(:name),
        dataset_estat_categories: dataset.estat_categories.order_by(order: 1).pluck(:name),
        full_url: dataset.full_url
      })

      next unless resource
      item.set({
        resource_name: resource.name,
        resource_filename: resource.filename,
        resource_source_url: resource.source_url
      })
    end
  end

  private

  def model
  end

  def items
    model.all
  end

  def put_log(message)
    Rails.logger.info(message)
    puts message
  end
end
