module Opendata::HistoryUpdateBase
  extend ActiveSupport::Concern

  def perform(*args)
    @options = args.extract_options!
    count = 0
    all_ids = items.pluck(:id)
    all_ids.each_slice(100) do |ids|
      items.in(id: ids).to_a.each do |item|
        count += 1
        put_log("update #{model} : #{count} / #{all_ids.count}")

        dataset = Opendata::Dataset.find(item.dataset_id) rescue nil
        resource = dataset.resources.where(id: item.resource_id).first if dataset.present?
        site = item.site.presence || dataset.try(:site).presence || resource.try(:site)
        item_attributes = {}
        item_attributes[:site_id] = site.try(:id)

        if dataset.present?
          item_attributes.merge!(
            dataset_name: dataset.name,
            dataset_areas: dataset.areas.order_by(order: 1).pluck(:name),
            dataset_categories: dataset.categories.order_by(order: 1).pluck(:name),
            dataset_estat_categories: dataset.estat_categories.order_by(order: 1).pluck(:name),
            full_url: dataset.full_url
          )

          if resource.present?
            item_attributes.merge!(
              resource_name: resource.name,
              resource_filename: resource.filename,
              resource_source_url: resource.source_url
            )
          end
        end

        item.set(item_attributes)
      end
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
