class Opendata::ResourceDownloadReportJob < Cms::ApplicationJob
  MODELS = [
    Opendata::ResourceDownloadHistory,
    Opendata::ResourceDatasetDownloadHistory,
    Opendata::ResourceBulkDownloadHistory
  ].freeze

  def perform(*args)
    @now = Time.zone.now

    start_at = args.shift
    start_at = start_at ? Time.zone.parse(start_at) : Time.zone.now.yesterday
    @start_at = start_at.beginning_of_day

    end_at = args.shift
    end_at = end_at ? Time.zone.parse(end_at) : @start_at
    @end_at = end_at.tomorrow.beginning_of_day

    build_results

    update_download_reports

    # 通常運用状態なら削除日時を更新する
    # それ以外（一括データ作成時など）では、削除日時は更新しない（別の/特注の削除日時設定パッチを実行してセットする）
    if @now.yesterday.to_date == @start_at.to_date
      update_deleted_on_download_report
    end

    true
  end

  private

  def build_results
    @results = []
    MODELS.each do |model|
      each_item(model.all, &method(:update_result))
    end
  end

  def update_download_reports
    @results.each do |item|
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
      r.dataset_url = item[:dataset_url].presence
      r.dataset_areas = item[:dataset_areas].presence
      r.dataset_categories = item[:dataset_categories].presence
      r.dataset_estat_categories = item[:dataset_estat_categories].presence
      r.resource_filename = item[:resource_filename].presence

      31.times do |i|
        count_field = "day#{i}_count".to_sym
        r[count_field] = item[count_field]
      end

      r.save
    end
  end

  def update_deleted_on_download_report
    year_month = @start_at.year * 100 + @start_at.month
    criteria = Opendata::ResourceDownloadReport.site(site).where(year_month: year_month).exists(deleted: false)
    all_dataset_ids = criteria.pluck(:dataset_id).uniq

    available_dataset_and_resources = Opendata::Dataset.site(site).in(id: all_dataset_ids).pluck(:id, "resources._id")
    available_dataset_and_resources.map! do |dataset_id, resources|
      if resources.blank?
        [ [ dataset_id, -1 ] ]
      else
        resources.map { |hash| [ dataset_id, hash["_id"] ] }
      end
    end
    available_dataset_and_resources.flatten!(1)

    all_ids = criteria.pluck(id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        found = available_dataset_and_resources.find do |dataset_id, resource_id|
          item.dataset_id == dataset_id && item.resource_id == resource_id
        end
        next if found.present?

        item.update(deleted: @now)
      end
    end
  end

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

  def update_result(item)
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

    dataset_url = item.full_url.presence
    dataset_areas = item.dataset_areas.presence
    dataset_categories = item.dataset_categories.presence
    dataset_estat_categories = item.dataset_estat_categories.presence

    found = @results.find do |item|
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

      if found[:downloaded] < downloaded
        found[:dataset_url] = dataset_url
        found[:dataset_areas] = dataset_areas
        found[:dataset_categories] = dataset_categories
        found[:dataset_estat_categories] = dataset_estat_categories
      end

      return
    end

    @results << {
      downloaded: downloaded, year: year, month: month, dataset_id: dataset_id, dataset_name: dataset_name,
      dataset_url: dataset_url, dataset_areas: dataset_areas, dataset_categories: dataset_categories,
      dataset_estat_categories: dataset_estat_categories, resource_id: resource_id, resource_name: resource_name,
      resource_filename: resource_filename, count_field => 1
    }
  end
end
