class Opendata::ResourceDownloadReportJob < Cms::ApplicationJob
  MODELS = [
    Opendata::ResourceDownloadHistory,
    Opendata::ResourceDatasetDownloadHistory,
    Opendata::ResourceBulkDownloadHistory
  ].freeze

  def perform(*args)
    start_at = args.shift
    start_at = start_at ? Time.zone.parse(start_at) : Time.zone.now.yesterday
    @start_at = start_at.beginning_of_day

    end_at = args.shift
    end_at = end_at ? Time.zone.parse(end_at) : @start_at
    @end_at = end_at.tomorrow.beginning_of_day

    @items = []
    MODELS.each do |model|
      each_item(model.all, &method(:set_result))
    end

    @items.each do |item|
      year = item[:year]
      month = item[:month]
      dataset_id = item[:dataset_id]
      dataset_name = item[:dataset_name].presence
      resource_id = item[:resource_id]
      resource_name = item[:resource_name].presence

      conditions = {
        year_month: year * 100 + month, dataset_id: dataset_id, dataset_name: dataset_name,
        resource_id: resource_id, resource_name: resource_name
      }
      r = Opendata::ResourceDownloadReport.site(site).where(conditions).first_or_create
      r.resource_filename ||= item[:resource_filename].presence
      31.times do |i|
        count_field = "day#{i}_count".to_sym
        r[count_field] = item[count_field]
      end

      r.save
    end

    true
  end

  private

  def each_item(base_criteria, &block)
    criteria = base_criteria.site(site)
    criteria = criteria.exists(resource_source_url: false)
    criteria = criteria.gte(downloaded: @start_at).lt(downloaded: @end_at)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      # load at once
      items = criteria.in(id: ids).to_a
      # call callback with item
      items.each(&block)
    end
  end

  def set_result(item)
    downloaded = item.downloaded
    year = downloaded.year
    month = downloaded.month
    day = downloaded.day
    count_field = "day#{day - 1}_count".to_sym
    dataset_id = item.dataset_id
    resource_id = item.resource_id

    dataset_name = item.dataset_name.presence
    resource_name = item.resource_name.presence
    resource_filename = item.resource_filename.presence

    found = @items.find do |item|
      next false unless item[:year] == year
      next false unless item[:month] == month
      next false unless item[:dataset_id] == dataset_id
      next false unless item[:dataset_name] == dataset_name
      next false unless item[:resource_id] == resource_id
      next false unless item[:resource_name] == resource_name

      true
    end

    if found
      found[count_field] ||= 0
      found[count_field] += 1
      return
    end

    @items << {
      downloaded: downloaded, year: year, month: month, dataset_id: dataset_id, dataset_name: dataset_name,
      resource_id: resource_id, resource_name: resource_name, resource_filename: resource_filename,
      count_field => 1
    }
  end
end
